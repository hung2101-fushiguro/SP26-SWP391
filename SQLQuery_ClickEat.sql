/* =========================================================
   CLICKEAT - FULL DATABASE SCRIPT
   Create DB -> Create Tables -> Seed Data (>=5 rows/table)
   Target: SQL Server / Azure SQL MI (Azure Data Studio)
   ========================================================= */

SET NOCOUNT ON;

------------------------------------------------------------
-- 0) CREATE DATABASE
------------------------------------------------------------
IF DB_ID(N'ClickEat') IS NULL
BEGIN
    CREATE DATABASE ClickEat;
END
GO

-- NOTE (Azure SQL Database - single DB):
-- If USE is not supported in your environment, connect directly to ClickEat
-- and run from the CREATE TABLE section onward.

USE ClickEat;
GO

/* =========================
   1) USERS & AUTH
   ========================= */

CREATE TABLE [Users] (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    full_name       NVARCHAR(100)    NOT NULL,
    email           NVARCHAR(150)    NULL,
    phone           NVARCHAR(20)     NOT NULL,
    password_hash   NVARCHAR(255)    NULL,
    role            NVARCHAR(20)     NOT NULL,  -- GUEST/CUSTOMER/MERCHANT/SHIPPER/ADMIN
    status          NVARCHAR(20)     NOT NULL DEFAULT 'ACTIVE', -- ACTIVE/INACTIVE
    created_at      DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at      DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME()
);

ALTER TABLE [Users]
ADD CONSTRAINT UQ_Users_Phone UNIQUE (phone);

ALTER TABLE [Users]
ADD CONSTRAINT UQ_Users_Email UNIQUE (email);

CREATE TABLE [UserAuthProviders] (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id          BIGINT           NOT NULL,
    provider         NVARCHAR(30)     NOT NULL, -- GOOGLE
    provider_user_id NVARCHAR(100)    NOT NULL, -- Google sub
    linked_at        DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_UserAuthProviders_User
        FOREIGN KEY (user_id) REFERENCES [Users](id) ON DELETE CASCADE
);

ALTER TABLE [UserAuthProviders]
ADD CONSTRAINT UQ_UserAuthProviders_Provider UNIQUE (provider, provider_user_id);

GO

/* =========================
   2) GUEST SESSION
   ========================= */

CREATE TABLE [GuestSessions] (
    guest_id      UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
    contact_phone NVARCHAR(20)     NULL,
    contact_email NVARCHAR(150)    NULL,
    created_at    DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    expires_at    DATETIME2        NULL
);
GO

/* =========================
   3) CUSTOMER PROFILE & ADDRESS (VN)
   ========================= */

CREATE TABLE [CustomerProfiles] (
    user_id            BIGINT      NOT NULL PRIMARY KEY,
    default_address_id BIGINT      NULL,
    created_at         DATETIME2   NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at         DATETIME2   NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_CustomerProfiles_User
        FOREIGN KEY (user_id) REFERENCES [Users](id) ON DELETE CASCADE
);

CREATE TABLE [Addresses] (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id        BIGINT          NOT NULL,

    receiver_name  NVARCHAR(100)   NOT NULL,
    receiver_phone NVARCHAR(20)    NOT NULL,

    address_line   NVARCHAR(255)   NOT NULL, -- số nhà, đường, chi tiết

    province_code  NVARCHAR(20)    NOT NULL,
    province_name  NVARCHAR(100)   NOT NULL,
    district_code  NVARCHAR(20)    NOT NULL,
    district_name  NVARCHAR(100)   NOT NULL,
    ward_code      NVARCHAR(20)    NOT NULL,
    ward_name      NVARCHAR(100)   NOT NULL,

    latitude       DECIMAL(10,7)   NULL,
    longitude      DECIMAL(10,7)   NULL,

    is_default     BIT             NOT NULL DEFAULT 0,
    note           NVARCHAR(255)   NULL,

    created_at     DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at     DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Addresses_User
        FOREIGN KEY (user_id) REFERENCES [Users](id) ON DELETE CASCADE
);

ALTER TABLE [CustomerProfiles]
ADD CONSTRAINT FK_CustomerProfiles_DefaultAddress
    FOREIGN KEY (default_address_id) REFERENCES [Addresses](id);

GO

/* =========================
   4) MERCHANT & KYC (NO CCCD)
   ========================= */

CREATE TABLE [MerchantProfiles] (
    user_id           BIGINT        NOT NULL PRIMARY KEY,
    shop_name         NVARCHAR(120) NOT NULL,
    shop_phone        NVARCHAR(20)  NOT NULL,

    shop_address_line NVARCHAR(255) NOT NULL,
    province_code     NVARCHAR(20)  NOT NULL,
    province_name     NVARCHAR(100) NOT NULL,
    district_code     NVARCHAR(20)  NOT NULL,
    district_name     NVARCHAR(100) NOT NULL,
    ward_code         NVARCHAR(20)  NOT NULL,
    ward_name         NVARCHAR(100) NOT NULL,

    latitude          DECIMAL(10,7) NULL,
    longitude         DECIMAL(10,7) NULL,

    status            NVARCHAR(20)  NOT NULL DEFAULT 'PENDING', -- PENDING/APPROVED/REJECTED/SUSPENDED
    created_at        DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_MerchantProfiles_User
        FOREIGN KEY (user_id) REFERENCES [Users](id) ON DELETE CASCADE
);

CREATE TABLE [MerchantKYC] (
    id                     BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id       BIGINT         NOT NULL,
    business_name          NVARCHAR(150)  NOT NULL,
    business_license_number NVARCHAR(50)  NULL,
    document_url           NVARCHAR(500)  NULL,

    submitted_at           DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    reviewed_by_admin_id   BIGINT         NULL,
    review_status          NVARCHAR(20)   NOT NULL DEFAULT 'PENDING', -- PENDING/APPROVED/REJECTED
    review_note            NVARCHAR(255)  NULL,

    CONSTRAINT FK_MerchantKYC_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES [MerchantProfiles](user_id) ON DELETE CASCADE,

    CONSTRAINT FK_MerchantKYC_Admin
        FOREIGN KEY (reviewed_by_admin_id) REFERENCES [Users](id)
);

GO

/* =========================
   5) MENU: CATEGORY & FOOD ITEM
   ========================= */

CREATE TABLE [Categories] (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id BIGINT         NOT NULL,
    name             NVARCHAR(100)  NOT NULL,
    is_active        BIT            NOT NULL DEFAULT 1,
    sort_order       INT            NOT NULL DEFAULT 0,

    CONSTRAINT FK_Categories_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES [MerchantProfiles](user_id) ON DELETE CASCADE
);

CREATE TABLE [FoodItems] (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id BIGINT         NOT NULL,
    category_id      BIGINT         NOT NULL,

    name             NVARCHAR(150)  NOT NULL,
    description      NVARCHAR(500)  NULL,
    price            DECIMAL(18,2)  NOT NULL,
    image_url        NVARCHAR(500)  NULL,
    is_available     BIT            NOT NULL DEFAULT 1,

    is_fried         BIT            NOT NULL DEFAULT 0, -- MVP health flag

    created_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_FoodItems_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES [MerchantProfiles](user_id) ON DELETE CASCADE,

    CONSTRAINT FK_FoodItems_Category
        FOREIGN KEY (category_id) REFERENCES [Categories](id)
);

CREATE INDEX IX_FoodItems_Merchant  ON [FoodItems](merchant_user_id);
CREATE INDEX IX_FoodItems_Category  ON [FoodItems](category_id);

GO

/* =========================
   6) CART (Guest + Customer)
   ========================= */

CREATE TABLE [Carts] (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,

    customer_user_id BIGINT            NULL,
    guest_id         UNIQUEIDENTIFIER  NULL,

    status           NVARCHAR(20)      NOT NULL DEFAULT 'ACTIVE', -- ACTIVE/CHECKED_OUT
    created_at       DATETIME2         NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2         NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Carts_Customer
        FOREIGN KEY (customer_user_id) REFERENCES [Users](id),

    CONSTRAINT FK_Carts_Guest
        FOREIGN KEY (guest_id) REFERENCES [GuestSessions](guest_id),

    CONSTRAINT CK_Carts_Owner
        CHECK (
            (customer_user_id IS NOT NULL AND guest_id IS NULL) OR
            (customer_user_id IS NULL AND guest_id IS NOT NULL)
        )
);

CREATE TABLE [CartItems] (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    cart_id             BIGINT        NOT NULL,
    food_item_id        BIGINT        NOT NULL,
    quantity            INT           NOT NULL,
    unit_price_snapshot DECIMAL(18,2) NOT NULL,
    note                NVARCHAR(255) NULL,

    CONSTRAINT FK_CartItems_Cart
        FOREIGN KEY (cart_id) REFERENCES [Carts](id) ON DELETE CASCADE,

    CONSTRAINT FK_CartItems_FoodItem
        FOREIGN KEY (food_item_id) REFERENCES [FoodItems](id)
);

CREATE INDEX IX_CartItems_Cart ON [CartItems](cart_id);

GO

/* =========================
   7) ORDER
   ========================= */

CREATE TABLE [Orders] (
    id                BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_code        NVARCHAR(30)     NOT NULL,

    customer_user_id  BIGINT           NULL,
    guest_id          UNIQUEIDENTIFIER NULL,

    merchant_user_id  BIGINT           NOT NULL,
    shipper_user_id   BIGINT           NULL,

    -- Delivery snapshot (VN)
    receiver_name     NVARCHAR(100)    NOT NULL,
    receiver_phone    NVARCHAR(20)     NOT NULL,
    delivery_address_line NVARCHAR(255) NOT NULL,

    province_code     NVARCHAR(20)     NOT NULL,
    province_name     NVARCHAR(100)    NOT NULL,
    district_code     NVARCHAR(20)     NOT NULL,
    district_name     NVARCHAR(100)    NOT NULL,
    ward_code         NVARCHAR(20)     NOT NULL,
    ward_name         NVARCHAR(100)    NOT NULL,

    latitude          DECIMAL(10,7)    NULL,
    longitude         DECIMAL(10,7)    NULL,

    delivery_note     NVARCHAR(255)    NULL,

    payment_method    NVARCHAR(20)     NOT NULL, -- COD/VNPAY
    payment_status    NVARCHAR(20)     NOT NULL DEFAULT 'UNPAID', -- UNPAID/PAID/FAILED

    order_status      NVARCHAR(30)     NOT NULL DEFAULT 'PLACED',
    -- PLACED/ACCEPTED/PREPARING/READY_FOR_PICKUP/PICKED_UP/DELIVERING/DELIVERED/CANCELLED/DELIVERY_FAILED

    subtotal_amount   DECIMAL(18,2)    NOT NULL DEFAULT 0,
    delivery_fee      DECIMAL(18,2)    NOT NULL DEFAULT 0,
    discount_amount   DECIMAL(18,2)    NOT NULL DEFAULT 0,
    total_amount      DECIMAL(18,2)    NOT NULL DEFAULT 0,

    created_at        DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    accepted_at       DATETIME2        NULL,
    ready_at          DATETIME2        NULL,
    picked_up_at      DATETIME2        NULL,
    delivered_at      DATETIME2        NULL,
    cancelled_at      DATETIME2        NULL,

    CONSTRAINT UQ_Orders_OrderCode UNIQUE(order_code),

    CONSTRAINT FK_Orders_Customer
        FOREIGN KEY (customer_user_id) REFERENCES [Users](id),

    CONSTRAINT FK_Orders_Guest
        FOREIGN KEY (guest_id) REFERENCES [GuestSessions](guest_id),

    CONSTRAINT FK_Orders_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES [MerchantProfiles](user_id),

    CONSTRAINT FK_Orders_Shipper
        FOREIGN KEY (shipper_user_id) REFERENCES [Users](id),

    CONSTRAINT CK_Orders_Owner
        CHECK (
            (customer_user_id IS NOT NULL AND guest_id IS NULL) OR
            (customer_user_id IS NULL AND guest_id IS NOT NULL)
        )
);

CREATE INDEX IX_Orders_Merchant_Status ON [Orders](merchant_user_id, order_status, created_at);
CREATE INDEX IX_Orders_Shipper_Status  ON [Orders](shipper_user_id, order_status, created_at);
CREATE INDEX IX_Orders_Customer_Created ON [Orders](customer_user_id, created_at);

CREATE TABLE [OrderItems] (
    id                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id           BIGINT         NOT NULL,
    food_item_id       BIGINT         NOT NULL,

    item_name_snapshot NVARCHAR(150)  NOT NULL,
    unit_price_snapshot DECIMAL(18,2) NOT NULL,
    quantity           INT            NOT NULL,
    note               NVARCHAR(255)  NULL,

    CONSTRAINT FK_OrderItems_Order
        FOREIGN KEY (order_id) REFERENCES [Orders](id) ON DELETE CASCADE,

    CONSTRAINT FK_OrderItems_FoodItem
        FOREIGN KEY (food_item_id) REFERENCES [FoodItems](id)
);

CREATE INDEX IX_OrderItems_Order ON [OrderItems](order_id);

CREATE TABLE [OrderStatusHistory] (
    id                BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id          BIGINT        NOT NULL,
    from_status       NVARCHAR(30)  NULL,
    to_status         NVARCHAR(30)  NOT NULL,

    updated_by_role   NVARCHAR(20)  NOT NULL, -- CUSTOMER/GUEST/MERCHANT/SHIPPER/ADMIN/SYSTEM
    updated_by_user_id BIGINT       NULL,

    note              NVARCHAR(255) NULL,
    created_at        DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_OrderStatusHistory_Order
        FOREIGN KEY (order_id) REFERENCES [Orders](id) ON DELETE CASCADE,

    CONSTRAINT FK_OrderStatusHistory_User
        FOREIGN KEY (updated_by_user_id) REFERENCES [Users](id)
);

CREATE INDEX IX_OrderStatusHistory_Order ON [OrderStatusHistory](order_id, created_at);

GO

/* =========================
   8) PAYMENT
   ========================= */

CREATE TABLE [PaymentTransactions] (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id         BIGINT         NOT NULL,
    provider         NVARCHAR(20)   NOT NULL, -- VNPAY/COD
    amount           DECIMAL(18,2)  NOT NULL,
    status           NVARCHAR(20)   NOT NULL, -- INITIATED/SUCCESS/FAILED
    provider_txn_ref NVARCHAR(100)  NULL,
    created_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_PaymentTransactions_Order
        FOREIGN KEY (order_id) REFERENCES [Orders](id) ON DELETE CASCADE
);

CREATE INDEX IX_PaymentTransactions_Order ON [PaymentTransactions](order_id);

GO

/* =========================
   9) VOUCHER
   ========================= */

CREATE TABLE [Vouchers] (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    code             NVARCHAR(50)   NOT NULL,
    discount_type    NVARCHAR(10)   NOT NULL, -- PERCENT/FIXED
    discount_value   DECIMAL(18,2)  NOT NULL,
    min_order_amount DECIMAL(18,2)  NULL,
    start_at         DATETIME2      NOT NULL,
    end_at           DATETIME2      NOT NULL,
    status           NVARCHAR(20)   NOT NULL DEFAULT 'ACTIVE', -- ACTIVE/INACTIVE
    CONSTRAINT UQ_Vouchers_Code UNIQUE(code)
);

CREATE TABLE [VoucherUsages] (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    voucher_id       BIGINT          NOT NULL,
    order_id         BIGINT          NOT NULL,
    customer_user_id BIGINT          NULL,
    guest_id         UNIQUEIDENTIFIER NULL,
    used_at          DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_VoucherUsages_Voucher
        FOREIGN KEY (voucher_id) REFERENCES [Vouchers](id),

    CONSTRAINT FK_VoucherUsages_Order
        FOREIGN KEY (order_id) REFERENCES [Orders](id) ON DELETE CASCADE,

    CONSTRAINT FK_VoucherUsages_Customer
        FOREIGN KEY (customer_user_id) REFERENCES [Users](id),

    CONSTRAINT FK_VoucherUsages_Guest
        FOREIGN KEY (guest_id) REFERENCES [GuestSessions](guest_id),

    CONSTRAINT CK_VoucherUsages_Owner
        CHECK (
            (customer_user_id IS NOT NULL AND guest_id IS NULL) OR
            (customer_user_id IS NULL AND guest_id IS NOT NULL)
        )
);

GO

/* =========================
   10) SHIPPER
   ========================= */

CREATE TABLE [ShipperProfiles] (
    user_id      BIGINT        NOT NULL PRIMARY KEY,
    vehicle_type NVARCHAR(20)  NOT NULL, -- MOTORBIKE/BIKE
    status       NVARCHAR(20)  NOT NULL DEFAULT 'ACTIVE', -- ACTIVE/SUSPENDED
    created_at   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_ShipperProfiles_User
        FOREIGN KEY (user_id) REFERENCES [Users](id) ON DELETE CASCADE
);

CREATE TABLE [ShipperAvailability] (
    shipper_user_id   BIGINT        NOT NULL PRIMARY KEY,
    is_online         BIT           NOT NULL DEFAULT 0,
    current_status    NVARCHAR(20)  NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE/BUSY
    current_latitude  DECIMAL(10,7) NULL,
    current_longitude DECIMAL(10,7) NULL,
    updated_at        DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_ShipperAvailability_Shipper
        FOREIGN KEY (shipper_user_id) REFERENCES [ShipperProfiles](user_id) ON DELETE CASCADE
);

CREATE INDEX IX_ShipperAvailability_Status ON [ShipperAvailability](is_online, current_status);

GO

/* =========================
   11) DELIVERY EXCEPTIONS
   ========================= */

CREATE TABLE [DeliveryIssues] (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id         BIGINT        NOT NULL,
    shipper_user_id  BIGINT        NOT NULL,

    issue_type      NVARCHAR(30)   NOT NULL, -- NO_ANSWER/WRONG_ADDRESS/REFUSED/WAIT_TOO_LONG/OTHER
    attempts_count  INT           NOT NULL DEFAULT 0,
    note            NVARCHAR(255) NULL,
    created_at      DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_DeliveryIssues_Order
        FOREIGN KEY (order_id) REFERENCES [Orders](id) ON DELETE CASCADE,

    CONSTRAINT FK_DeliveryIssues_Shipper
        FOREIGN KEY (shipper_user_id) REFERENCES [Users](id)
);

CREATE TABLE [FailedDeliveryResolutions] (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id             BIGINT        NOT NULL,
    handled_by_admin_id  BIGINT        NOT NULL,

    resolution_type     NVARCHAR(30)   NOT NULL, -- RETRY/CANCEL/RETURNED/DISPOSED
    note                NVARCHAR(255) NULL,
    created_at          DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_FailedDeliveryResolutions_Order
        FOREIGN KEY (order_id) REFERENCES [Orders](id) ON DELETE CASCADE,

    CONSTRAINT FK_FailedDeliveryResolutions_Admin
        FOREIGN KEY (handled_by_admin_id) REFERENCES [Users](id)
);

GO

/* =========================
   12) RATING
   ========================= */

CREATE TABLE [Ratings] (
    id                BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id          BIGINT          NOT NULL,

    rater_customer_id BIGINT          NULL,
    rater_guest_id    UNIQUEIDENTIFIER NULL,

    target_type       NVARCHAR(20)    NOT NULL, -- MERCHANT/SHIPPER
    target_user_id    BIGINT          NOT NULL,

    stars             INT             NOT NULL,
    comment           NVARCHAR(500)   NULL,
    created_at        DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Ratings_Order
        FOREIGN KEY (order_id) REFERENCES [Orders](id) ON DELETE CASCADE,

    CONSTRAINT FK_Ratings_RaterCustomer
        FOREIGN KEY (rater_customer_id) REFERENCES [Users](id),

    CONSTRAINT FK_Ratings_RaterGuest
        FOREIGN KEY (rater_guest_id) REFERENCES [GuestSessions](guest_id),

    CONSTRAINT FK_Ratings_TargetUser
        FOREIGN KEY (target_user_id) REFERENCES [Users](id),

    CONSTRAINT CK_Ratings_Rater
        CHECK (
            (rater_customer_id IS NOT NULL AND rater_guest_id IS NULL) OR
            (rater_customer_id IS NULL AND rater_guest_id IS NOT NULL)
        ),

    CONSTRAINT CK_Ratings_Stars CHECK (stars BETWEEN 1 AND 5)
);

CREATE INDEX IX_Ratings_Target ON [Ratings](target_type, target_user_id);

GO

/* =========================
   13) AI BEHAVIOR EVENTS (Customer-only)
   ========================= */

CREATE TABLE [UserBehaviorEvents] (
    id                BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_user_id  BIGINT         NOT NULL,

    event_type        NVARCHAR(30)   NOT NULL, -- VIEW_ITEM/SEARCH/ADD_TO_CART/ORDER_PLACED
    food_item_id      BIGINT         NULL,
    keyword           NVARCHAR(200)  NULL,
    created_at        DATETIME2      NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_UserBehaviorEvents_Customer
        FOREIGN KEY (customer_user_id) REFERENCES [Users](id) ON DELETE CASCADE,

    CONSTRAINT FK_UserBehaviorEvents_FoodItem
        FOREIGN KEY (food_item_id) REFERENCES [FoodItems](id)
);

CREATE INDEX IX_UserBehaviorEvents_UserTime ON [UserBehaviorEvents](customer_user_id, created_at);

GO

/* =========================
   14) NOTIFICATIONS
   ========================= */

CREATE TABLE [Notifications] (
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id    BIGINT           NULL,
    guest_id   UNIQUEIDENTIFIER NULL,

    type       NVARCHAR(50)     NOT NULL,
    content    NVARCHAR(500)    NOT NULL,
    is_read    BIT              NOT NULL DEFAULT 0,
    created_at DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Notifications_User
        FOREIGN KEY (user_id) REFERENCES [Users](id),

    CONSTRAINT FK_Notifications_Guest
        FOREIGN KEY (guest_id) REFERENCES [GuestSessions](guest_id),

    CONSTRAINT CK_Notifications_Target
        CHECK (
            (user_id IS NOT NULL AND guest_id IS NULL) OR
            (user_id IS NULL AND guest_id IS NOT NULL)
        )
);

CREATE INDEX IX_Notifications_User ON [Notifications](user_id, is_read, created_at);

GO

/* =========================================================
   SEED DATA (>= 5 rows/table)
   NOTE: Do NOT put GO inside this seed block because it uses variables.
   ========================================================= */

BEGIN TRY
    BEGIN TRAN;

    ------------------------------------------------------------
    -- 1) USERS (16 rows: 1 admin, 5 merchants, 5 shippers, 5 customers)
    ------------------------------------------------------------
    INSERT INTO [Users] (full_name, email, phone, password_hash, role, status)
    VALUES
    (N'Admin ClickEat',      N'admin@clickeat.vn',   N'0900000001', N'hash_admin',   N'ADMIN',   N'ACTIVE'),
    (N'Gà Rán A',            N'merchant1@shop.vn',   N'0900000002', N'hash_m1',      N'MERCHANT',N'ACTIVE'),
    (N'Gà Rán B',            N'merchant2@shop.vn',   N'0900000003', N'hash_m2',      N'MERCHANT',N'ACTIVE'),
    (N'Gà Rán C',            N'merchant3@shop.vn',   N'0900000004', N'hash_m3',      N'MERCHANT',N'ACTIVE'),
    (N'Gà Rán D',            N'merchant4@shop.vn',   N'0900000005', N'hash_m4',      N'MERCHANT',N'ACTIVE'),
    (N'Gà Rán E',            N'merchant5@shop.vn',   N'0900000006', N'hash_m5',      N'MERCHANT',N'ACTIVE'),
    (N'Shipper An',          N'shipper1@clickeat.vn',N'0900000007', N'hash_s1',      N'SHIPPER', N'ACTIVE'),
    (N'Shipper Bình',        N'shipper2@clickeat.vn',N'0900000008', N'hash_s2',      N'SHIPPER', N'ACTIVE'),
    (N'Shipper Chi',         N'shipper3@clickeat.vn',N'0900000009', N'hash_s3',      N'SHIPPER', N'ACTIVE'),
    (N'Shipper Dũng',        N'shipper4@clickeat.vn',N'0900000010', N'hash_s4',      N'SHIPPER', N'ACTIVE'),
    (N'Shipper Em',          N'shipper5@clickeat.vn',N'0900000011', N'hash_s5',      N'SHIPPER', N'ACTIVE'),
    (N'Khách Huy',           N'customer1@clickeat.vn',N'0900000012',N'hash_c1',      N'CUSTOMER',N'ACTIVE'),
    (N'Khách Lan',           N'customer2@clickeat.vn',N'0900000013',N'hash_c2',      N'CUSTOMER',N'ACTIVE'),
    (N'Khách Minh',          N'customer3@clickeat.vn',N'0900000014',N'hash_c3',      N'CUSTOMER',N'ACTIVE'),
    (N'Khách Nga',           N'customer4@clickeat.vn',N'0900000015',N'hash_c4',      N'CUSTOMER',N'ACTIVE'),
    (N'Khách Phúc',          N'customer5@clickeat.vn',N'0900000016',N'hash_c5',      N'CUSTOMER',N'ACTIVE');

    ------------------------------------------------------------
    -- 2) UserAuthProviders (Google) - 5 rows for customers 12-16
    ------------------------------------------------------------
    INSERT INTO [UserAuthProviders] (user_id, provider, provider_user_id)
    VALUES
    (12, N'GOOGLE', N'google-sub-12'),
    (13, N'GOOGLE', N'google-sub-13'),
    (14, N'GOOGLE', N'google-sub-14'),
    (15, N'GOOGLE', N'google-sub-15'),
    (16, N'GOOGLE', N'google-sub-16');

    ------------------------------------------------------------
    -- 3) GuestSessions - 5 rows (GUID variables)
    ------------------------------------------------------------
    DECLARE @g1 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g2 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g3 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g4 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g5 UNIQUEIDENTIFIER = NEWID();

    INSERT INTO [GuestSessions] (guest_id, contact_phone, contact_email, expires_at)
    VALUES
    (@g1, N'0987000001', N'guest1@mail.com', DATEADD(DAY, 7, SYSUTCDATETIME())),
    (@g2, N'0987000002', N'guest2@mail.com', DATEADD(DAY, 7, SYSUTCDATETIME())),
    (@g3, N'0987000003', N'guest3@mail.com', DATEADD(DAY, 7, SYSUTCDATETIME())),
    (@g4, N'0987000004', N'guest4@mail.com', DATEADD(DAY, 7, SYSUTCDATETIME())),
    (@g5, N'0987000005', N'guest5@mail.com', DATEADD(DAY, 7, SYSUTCDATETIME()));

    ------------------------------------------------------------
    -- 4) CustomerProfiles - 5 rows
    ------------------------------------------------------------
    INSERT INTO [CustomerProfiles] (user_id)
    VALUES (12),(13),(14),(15),(16);

    ------------------------------------------------------------
    -- 5) Addresses - 5 rows (VN)
    ------------------------------------------------------------
    INSERT INTO [Addresses]
    (user_id, receiver_name, receiver_phone, address_line,
     province_code, province_name, district_code, district_name, ward_code, ward_name,
     latitude, longitude, is_default, note)
    VALUES
    (12, N'Huy',  N'0900000012', N'12 Nguyễn Huệ',         N'79', N'TP.HCM', N'760', N'Quận 1',  N'26734', N'Bến Nghé', 10.7765300, 106.7009800, 1, N'Gọi trước khi giao'),
    (13, N'Lan',  N'0900000013', N'34 Lê Lợi',             N'79', N'TP.HCM', N'760', N'Quận 1',  N'26737', N'Bến Thành',10.7721600, 106.6981700, 1, NULL),
    (14, N'Minh', N'0900000014', N'88 Điện Biên Phủ',      N'79', N'TP.HCM', N'769', N'Bình Thạnh',N'27145', N'Phường 21',10.8052000, 106.7129000, 1, N'Để lễ tân'),
    (15, N'Nga',  N'0900000015', N'15 Võ Văn Ngân',        N'79', N'TP.HCM', N'762', N'Thủ Đức', N'26848', N'Linh Chiểu',10.8514000,106.7579000, 1, NULL),
    (16, N'Phúc', N'0900000016', N'20 Nguyễn Văn Linh',    N'48', N'Đà Nẵng',N'490', N'Hải Châu',N'20194', N'Phước Ninh',16.0606000,108.2222000, 1, N'Giao giờ trưa');

    -- Addresses IDs expected 1..5 in new DB
    UPDATE [CustomerProfiles] SET default_address_id = 1 WHERE user_id = 12;
    UPDATE [CustomerProfiles] SET default_address_id = 2 WHERE user_id = 13;
    UPDATE [CustomerProfiles] SET default_address_id = 3 WHERE user_id = 14;
    UPDATE [CustomerProfiles] SET default_address_id = 4 WHERE user_id = 15;
    UPDATE [CustomerProfiles] SET default_address_id = 5 WHERE user_id = 16;

    ------------------------------------------------------------
    -- 6) MerchantProfiles - 5 rows (merchants 2..6)
    ------------------------------------------------------------
    INSERT INTO [MerchantProfiles]
    (user_id, shop_name, shop_phone, shop_address_line,
     province_code, province_name, district_code, district_name, ward_code, ward_name,
     latitude, longitude, status)
    VALUES
    (2, N'Lollibee Q1', N'0280000002', N'10 Đồng Khởi',      N'79', N'TP.HCM', N'760', N'Quận 1', N'26734', N'Bến Nghé', 10.7750000,106.7040000, N'APPROVED'),
    (3, N'Lollibee Q3', N'0280000003', N'250 CMT8',          N'79', N'TP.HCM', N'770', N'Quận 3', N'27349', N'Phường 10',10.7840000,106.6800000, N'APPROVED'),
    (4, N'Lollibee BT', N'0280000004', N'120 Xô Viết Nghệ Tĩnh',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.8040000,106.7130000, N'APPROVED'),
    (5, N'Lollibee TD', N'0280000005', N'5 Kha Vạn Cân',     N'79', N'TP.HCM', N'762', N'Thủ Đức',N'26848', N'Linh Chiểu',10.8500000,106.7580000, N'PENDING'),
    (6, N'Lollibee DN', N'0236000006', N'99 Nguyễn Văn Linh',N'48', N'Đà Nẵng',N'490', N'Hải Châu',N'20194', N'Phước Ninh',16.0600000,108.2220000, N'PENDING');

    ------------------------------------------------------------
    -- 7) MerchantKYC - 5 rows (no CCCD)
    ------------------------------------------------------------
    INSERT INTO [MerchantKYC]
    (merchant_user_id, business_name, business_license_number, document_url, reviewed_by_admin_id, review_status, review_note)
    VALUES
    (2, N'Hộ KD Lollibee Q1', N'GP-001', N'https://example.com/kyc/m1.pdf', 1, N'APPROVED', N'OK'),
    (3, N'Hộ KD Lollibee Q3', N'GP-002', N'https://example.com/kyc/m2.pdf', 1, N'APPROVED', N'OK'),
    (4, N'Hộ KD Lollibee BT', N'GP-003', N'https://example.com/kyc/m3.pdf', 1, N'APPROVED', N'OK'),
    (5, N'Hộ KD Lollibee TD', NULL,      N'https://example.com/kyc/m4.pdf', 1, N'PENDING',  NULL),
    (6, N'Hộ KD Lollibee DN', NULL,      N'https://example.com/kyc/m5.pdf', 1, N'REJECTED', N'Thiếu thông tin');

    ------------------------------------------------------------
    -- 8) Categories - 5 rows
    ------------------------------------------------------------
    INSERT INTO [Categories] (merchant_user_id, name, is_active, sort_order)
    VALUES
    (2, N'Gà rán', 1, 1),
    (3, N'Combo',  1, 1),
    (4, N'Burger', 1, 1),
    (5, N'Đồ uống',1, 1),
    (6, N'Tráng miệng',1,1);

    ------------------------------------------------------------
    -- 9) FoodItems - 10 rows
    ------------------------------------------------------------
    INSERT INTO [FoodItems]
    (merchant_user_id, category_id, name, description, price, image_url, is_available, is_fried)
    VALUES
    (2, 1, N'Gà rán giòn', N'Gà rán truyền thống', 45000, NULL, 1, 1),
    (2, 1, N'Gà cay',      N'Gà rán sốt cay',      50000, NULL, 1, 1),
    (3, 2, N'Combo 1',     N'Gà + khoai + nước',   79000, NULL, 1, 1),
    (3, 2, N'Combo 2',     N'Gà + burger + nước',  89000, NULL, 1, 1),
    (4, 3, N'Burger gà',   N'Burger gà giòn',      55000, NULL, 1, 1),
    (4, 3, N'Burger cá',   N'Burger cá',           52000, NULL, 1, 0),
    (5, 4, N'Trà đào',     N'Nước uống',           30000, NULL, 1, 0),
    (5, 4, N'Coca',        N'Nước uống',           20000, NULL, 1, 0),
    (6, 5, N'Kem vani',    N'Tráng miệng',         25000, NULL, 1, 0),
    (6, 5, N'Bánh flan',   N'Tráng miệng',         22000, NULL, 1, 0);

    ------------------------------------------------------------
    -- 10) Carts - 5 rows (3 customer + 2 guest)
    ------------------------------------------------------------
    INSERT INTO [Carts] (customer_user_id, guest_id, status)
    VALUES
    (12, NULL, N'ACTIVE'),
    (13, NULL, N'ACTIVE'),
    (14, NULL, N'ACTIVE'),
    (NULL, @g1, N'ACTIVE'),
    (NULL, @g2, N'ACTIVE');

    ------------------------------------------------------------
    -- 11) CartItems - 5 rows
    ------------------------------------------------------------
    INSERT INTO [CartItems] (cart_id, food_item_id, quantity, unit_price_snapshot, note)
    VALUES
    (1, 1, 2, 45000, NULL),
    (2, 3, 1, 79000, N'Ít đá'),
    (3, 7, 2, 30000, NULL),
    (4, 5, 1, 55000, NULL),
    (5, 9, 3, 25000, N'Giao nhanh');

    ------------------------------------------------------------
    -- 12) Orders - 5 rows (3 customer + 2 guest)
    ------------------------------------------------------------
    INSERT INTO [Orders]
    (order_code, customer_user_id, guest_id, merchant_user_id, shipper_user_id,
     receiver_name, receiver_phone, delivery_address_line,
     province_code, province_name, district_code, district_name, ward_code, ward_name,
     latitude, longitude, delivery_note,
     payment_method, payment_status, order_status,
     subtotal_amount, delivery_fee, discount_amount, total_amount,
     accepted_at, ready_at, picked_up_at, delivered_at, cancelled_at)
    VALUES
    (N'ORD0001', 12, NULL, 2, 7,
     N'Huy', N'0900000012', N'12 Nguyễn Huệ',
     N'79', N'TP.HCM', N'760', N'Quận 1', N'26734', N'Bến Nghé',
     10.7765300,106.7009800, N'Gọi trước',
     N'COD', N'UNPAID', N'DELIVERED',
     90000, 15000, 0, 105000,
     DATEADD(MINUTE,-40,SYSUTCDATETIME()), DATEADD(MINUTE,-30,SYSUTCDATETIME()), DATEADD(MINUTE,-25,SYSUTCDATETIME()), DATEADD(MINUTE,-5,SYSUTCDATETIME()), NULL),

    (N'ORD0002', 13, NULL, 3, 8,
     N'Lan', N'0900000013', N'34 Lê Lợi',
     N'79', N'TP.HCM', N'760', N'Quận 1', N'26737', N'Bến Thành',
     10.7721600,106.6981700, NULL,
     N'VNPAY', N'PAID', N'DELIVERING',
     79000, 15000, 5000, 89000,
     DATEADD(MINUTE,-25,SYSUTCDATETIME()), DATEADD(MINUTE,-15,SYSUTCDATETIME()), DATEADD(MINUTE,-10,SYSUTCDATETIME()), NULL, NULL),

    (N'ORD0003', 14, NULL, 4, NULL,
     N'Minh', N'0900000014', N'88 Điện Biên Phủ',
     N'79', N'TP.HCM', N'769', N'Bình Thạnh', N'27145', N'Phường 21',
     10.8052000,106.7129000, N'Để lễ tân',
     N'COD', N'UNPAID', N'READY_FOR_PICKUP',
     55000, 12000, 0, 67000,
     DATEADD(MINUTE,-20,SYSUTCDATETIME()), DATEADD(MINUTE,-5,SYSUTCDATETIME()), NULL, NULL, NULL),

    (N'ORD0004', NULL, @g1, 2, 9,
     N'Guest 1', N'0987000001', N'100 Lý Tự Trọng',
     N'79', N'TP.HCM', N'760', N'Quận 1', N'26734', N'Bến Nghé',
     10.7759000,106.7001000, NULL,
     N'COD', N'UNPAID', N'DELIVERY_FAILED',
     50000, 15000, 0, 65000,
     DATEADD(MINUTE,-35,SYSUTCDATETIME()), DATEADD(MINUTE,-25,SYSUTCDATETIME()), DATEADD(MINUTE,-15,SYSUTCDATETIME()), NULL, NULL),

    (N'ORD0005', NULL, @g2, 3, NULL,
     N'Guest 2', N'0987000002', N'50 Pasteur',
     N'79', N'TP.HCM', N'760', N'Quận 1', N'26737', N'Bến Thành',
     10.7718000,106.6990000, N'Hủy nếu chờ lâu',
     N'VNPAY', N'FAILED', N'CANCELLED',
     89000, 15000, 0, 104000,
     NULL, NULL, NULL, NULL, SYSUTCDATETIME());

    ------------------------------------------------------------
    -- 13) OrderItems - 5 rows
    ------------------------------------------------------------
    INSERT INTO [OrderItems] (order_id, food_item_id, item_name_snapshot, unit_price_snapshot, quantity, note)
    VALUES
    (1, 1, N'Gà rán giòn', 45000, 2, NULL),
    (2, 3, N'Combo 1',     79000, 1, NULL),
    (3, 5, N'Burger gà',   55000, 1, NULL),
    (4, 2, N'Gà cay',      50000, 1, NULL),
    (5, 4, N'Combo 2',     89000, 1, NULL);

    ------------------------------------------------------------
    -- 14) OrderStatusHistory - 10 rows
    ------------------------------------------------------------
    INSERT INTO [OrderStatusHistory] (order_id, from_status, to_status, updated_by_role, updated_by_user_id, note)
    VALUES
    (1, NULL, N'PLACED',        N'CUSTOMER', 12, NULL),
    (1, N'PLACED', N'ACCEPTED',  N'MERCHANT', 2,  NULL),
    (1, N'ACCEPTED',N'PREPARING',N'MERCHANT', 2,  NULL),
    (1, N'PREPARING',N'READY_FOR_PICKUP',N'MERCHANT',2,NULL),
    (1, N'READY_FOR_PICKUP',N'PICKED_UP',N'SHIPPER',7,NULL),
    (1, N'PICKED_UP',N'DELIVERED',N'SHIPPER',7,NULL),

    (4, NULL, N'PLACED',        N'GUEST', NULL, NULL),
    (4, N'PLACED', N'ACCEPTED',  N'MERCHANT', 2,  NULL),
    (4, N'ACCEPTED',N'DELIVERING',N'SHIPPER', 9, NULL),
    (4, N'DELIVERING',N'DELIVERY_FAILED',N'SHIPPER',9, N'No answer');

    ------------------------------------------------------------
    -- 15) PaymentTransactions - 5 rows
    ------------------------------------------------------------
    INSERT INTO [PaymentTransactions] (order_id, provider, amount, status, provider_txn_ref)
    VALUES
    (1, N'COD',   105000, N'INITIATED', NULL),
    (2, N'VNPAY',  89000, N'SUCCESS',   N'VNPAY-TXN-0002'),
    (3, N'COD',    67000, N'INITIATED', NULL),
    (4, N'COD',    65000, N'FAILED',    NULL),
    (5, N'VNPAY', 104000, N'FAILED',    N'VNPAY-TXN-0005');

    ------------------------------------------------------------
    -- 16) Vouchers - 5 rows
    ------------------------------------------------------------
    INSERT INTO [Vouchers] (code, discount_type, discount_value, min_order_amount, start_at, end_at, status)
    VALUES
    (N'CLICK5',  N'FIXED',   5000,  50000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,30,SYSUTCDATETIME()), N'ACTIVE'),
    (N'CLICK10', N'PERCENT', 10,    80000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,30,SYSUTCDATETIME()), N'ACTIVE'),
    (N'FRYFREE', N'FIXED',   10000, 90000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,10,SYSUTCDATETIME()), N'ACTIVE'),
    (N'NEWUSER', N'FIXED',   15000, 70000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,20,SYSUTCDATETIME()), N'ACTIVE'),
    (N'WEEKEND', N'PERCENT', 5,     40000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,60,SYSUTCDATETIME()), N'INACTIVE');

    ------------------------------------------------------------
    -- 17) VoucherUsages - 5 rows
    ------------------------------------------------------------
    INSERT INTO [VoucherUsages] (voucher_id, order_id, customer_user_id, guest_id)
    VALUES
    (1, 2, 13, NULL),
    (2, 1, 12, NULL),
    (3, 3, 14, NULL),
    (4, 4, NULL, @g1),
    (5, 5, NULL, @g2);

    ------------------------------------------------------------
    -- 18) ShipperProfiles - 5 rows (7..11)
    ------------------------------------------------------------
    INSERT INTO [ShipperProfiles] (user_id, vehicle_type, status)
    VALUES
    (7,  N'MOTORBIKE', N'ACTIVE'),
    (8,  N'MOTORBIKE', N'ACTIVE'),
    (9,  N'MOTORBIKE', N'ACTIVE'),
    (10, N'BIKE',      N'ACTIVE'),
    (11, N'MOTORBIKE', N'ACTIVE');

    ------------------------------------------------------------
    -- 19) ShipperAvailability - 5 rows
    ------------------------------------------------------------
    INSERT INTO [ShipperAvailability]
    (shipper_user_id, is_online, current_status, current_latitude, current_longitude)
    VALUES
    (7,  1, N'BUSY',      10.7760000, 106.7010000),
    (8,  1, N'BUSY',      10.7725000, 106.6985000),
    (9,  1, N'AVAILABLE', 10.7758000, 106.7002000),
    (10, 1, N'AVAILABLE', 10.8050000, 106.7135000),
    (11, 0, N'AVAILABLE', NULL,       NULL);

    ------------------------------------------------------------
    -- 20) DeliveryIssues - 5 rows
    ------------------------------------------------------------
    INSERT INTO [DeliveryIssues] (order_id, shipper_user_id, issue_type, attempts_count, note)
    VALUES
    (4, 9,  N'NO_ANSWER',     3, N'Khách không nghe máy'),
    (2, 8,  N'WRONG_ADDRESS', 1, N'Địa chỉ thiếu số nhà'),
    (1, 7,  N'OTHER',         0, N'Giao trễ do kẹt xe'),
    (4, 9,  N'WAIT_TOO_LONG', 1, N'Chờ 10 phút không gặp'),
    (5, 10, N'NO_ANSWER',     2, N'Khách bận');

    ------------------------------------------------------------
    -- 21) FailedDeliveryResolutions - 5 rows
    ------------------------------------------------------------
    INSERT INTO [FailedDeliveryResolutions] (order_id, handled_by_admin_id, resolution_type, note)
    VALUES
    (4, 1, N'CANCEL',   N'Giao thất bại - hủy đơn'),
    (2, 1, N'RETRY',    N'Liên hệ khách cập nhật địa chỉ'),
    (1, 1, N'RETURNED', N'Ghi nhận hoàn về (demo)'),
    (5, 1, N'CANCEL',   N'Thanh toán thất bại - hủy'),
    (3, 1, N'RETRY',    N'Chờ shipper nhận đơn');

    ------------------------------------------------------------
    -- 22) Ratings - 5 rows
    ------------------------------------------------------------
    INSERT INTO [Ratings] (order_id, rater_customer_id, rater_guest_id, target_type, target_user_id, stars, comment)
    VALUES
    (1, 12, NULL, N'SHIPPER',  7,  5, N'Giao nhanh, thân thiện'),
    (1, 12, NULL, N'MERCHANT', 2,  4, N'Đồ ăn ngon'),
    (2, 13, NULL, N'MERCHANT', 3,  5, N'Combo ổn, đóng gói tốt'),
    (4, NULL, @g1, N'SHIPPER', 9,  2, N'Gọi không được'),
    (5, NULL, @g2, N'MERCHANT',3,  3, N'Đặt không thành công');

    ------------------------------------------------------------
    -- 23) UserBehaviorEvents - 5 rows
    ------------------------------------------------------------
    INSERT INTO [UserBehaviorEvents] (customer_user_id, event_type, food_item_id, keyword)
    VALUES
    (12, N'VIEW_ITEM',    1,    NULL),
    (13, N'SEARCH',       NULL, N'combo'),
    (14, N'ADD_TO_CART',  5,    NULL),
    (15, N'VIEW_ITEM',    2,    NULL),
    (16, N'ORDER_PLACED', 3,    NULL);

    ------------------------------------------------------------
    -- 24) Notifications - 5 rows
    ------------------------------------------------------------
    INSERT INTO [Notifications] (user_id, guest_id, type, content, is_read)
    VALUES
    (12, NULL, N'ORDER_CONFIRMED', N'Đơn ORD0001 đã được xác nhận.', 1),
    (13, NULL, N'STATUS_CHANGED',  N'Đơn ORD0002 đang được giao.',   0),
    (NULL,@g1, N'DELIVERY_FAILED', N'Đơn ORD0004 giao thất bại. Vui lòng liên hệ hỗ trợ.', 0),
    (2,  NULL, N'NEW_ORDER',       N'Bạn có đơn hàng mới ORD0003.', 0),
    (7,  NULL, N'ASSIGNED_ORDER',  N'Bạn được gán đơn ORD0001.',    1);

    COMMIT TRAN;

    PRINT N'✅ ClickEat DB created + tables created + seeded successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;

    DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'❌ ERROR: ' + @Err;
    THROW;
END CATCH;
