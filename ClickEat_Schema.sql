/*(index):64  cdn.tailwindcss.com should not be used in production. To use Tailwind CSS in production, install it as a PostCSS plugin or use the Tailwind CLI: https://tailwindcss.com/docs/installation
(anonymous) @ (index):64
merchant/api/dashboard:1   Failed to load resource: the server responded with a status of 401 ()
[NEW] Explain Console errors by using Copilot in Edge: click
         
         to explain an error. 
        Learn more
        Don't show again
FULL SCHEMA + SEED + EXTRA + THÁNG 2) - SQL SERVER
   One-shot script: Create DB -> Drop old tables -> Create schema -> Trigger -> Seed -> Extra -> Tháng 2
   Includes: WithdrawalRequests, business_hours, avatar_url from migrations
   Fixed:
   - No multiple cascade paths (AutoCartProposals merchant FK NO ACTION)
   - Trigger uses table variable (no CTE scope issue)
   - Order/Payment status flows aligned
   - Voucher merchant-scoped + publish + limits
   - Shipper first-accept via OrderClaims
   - AI chat + AutoCart proposals
   ========================================================= */

SET NOCOUNT ON;
GO

/* =========================
   0) CREATE DATABASE
   ========================= */
IF DB_ID(N'ClickEat') IS NULL
BEGIN
    CREATE DATABASE ClickEat;
END
GO

USE ClickEat;
GO

/* =========================
   1) DROP TABLES (for rerun)
   ========================= */
DROP TRIGGER IF EXISTS dbo.TR_CartItems_EnforceSingleMerchant;
GO

IF OBJECT_ID('dbo.AutoCartProposalItems','U') IS NOT NULL DROP TABLE dbo.AutoCartProposalItems;
IF OBJECT_ID('dbo.AutoCartProposals','U') IS NOT NULL DROP TABLE dbo.AutoCartProposals;
IF OBJECT_ID('dbo.AIMessages','U') IS NOT NULL DROP TABLE dbo.AIMessages;
IF OBJECT_ID('dbo.AIConversations','U') IS NOT NULL DROP TABLE dbo.AIConversations;

IF OBJECT_ID('dbo.WithdrawalRequests','U') IS NOT NULL DROP TABLE dbo.WithdrawalRequests;

IF OBJECT_ID('dbo.UserBehaviorEvents','U') IS NOT NULL DROP TABLE dbo.UserBehaviorEvents;
IF OBJECT_ID('dbo.Notifications','U') IS NOT NULL DROP TABLE dbo.Notifications;

IF OBJECT_ID('dbo.Ratings','U') IS NOT NULL DROP TABLE dbo.Ratings;

IF OBJECT_ID('dbo.FailedDeliveryResolutions','U') IS NOT NULL DROP TABLE dbo.FailedDeliveryResolutions;
IF OBJECT_ID('dbo.DeliveryIssues','U') IS NOT NULL DROP TABLE dbo.DeliveryIssues;

IF OBJECT_ID('dbo.OrderClaims','U') IS NOT NULL DROP TABLE dbo.OrderClaims;

IF OBJECT_ID('dbo.ShipperAvailability','U') IS NOT NULL DROP TABLE dbo.ShipperAvailability;
IF OBJECT_ID('dbo.ShipperProfiles','U') IS NOT NULL DROP TABLE dbo.ShipperProfiles;

IF OBJECT_ID('dbo.VoucherUsages','U') IS NOT NULL DROP TABLE dbo.VoucherUsages;
IF OBJECT_ID('dbo.Vouchers','U') IS NOT NULL DROP TABLE dbo.Vouchers;

IF OBJECT_ID('dbo.PaymentTransactions','U') IS NOT NULL DROP TABLE dbo.PaymentTransactions;

IF OBJECT_ID('dbo.OrderStatusHistory','U') IS NOT NULL DROP TABLE dbo.OrderStatusHistory;
IF OBJECT_ID('dbo.OrderItems','U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE dbo.Orders;

IF OBJECT_ID('dbo.CartItems','U') IS NOT NULL DROP TABLE dbo.CartItems;
IF OBJECT_ID('dbo.Carts','U') IS NOT NULL DROP TABLE dbo.Carts;

IF OBJECT_ID('dbo.FoodItems','U') IS NOT NULL DROP TABLE dbo.FoodItems;
IF OBJECT_ID('dbo.Categories','U') IS NOT NULL DROP TABLE dbo.Categories;

IF OBJECT_ID('dbo.MerchantKYC','U') IS NOT NULL DROP TABLE dbo.MerchantKYC;
IF OBJECT_ID('dbo.MerchantProfiles','U') IS NOT NULL DROP TABLE dbo.MerchantProfiles;

IF OBJECT_ID('dbo.CustomerProfiles','U') IS NOT NULL DROP TABLE dbo.CustomerProfiles;
IF OBJECT_ID('dbo.Addresses','U') IS NOT NULL DROP TABLE dbo.Addresses;

IF OBJECT_ID('dbo.GuestSessions','U') IS NOT NULL DROP TABLE dbo.GuestSessions;

IF OBJECT_ID('dbo.UserAuthProviders','U') IS NOT NULL DROP TABLE dbo.UserAuthProviders;
IF OBJECT_ID('dbo.Users','U') IS NOT NULL DROP TABLE dbo.Users;
GO


/* =========================
   2) USERS & AUTH
   ========================= */

CREATE TABLE dbo.Users (
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    full_name     NVARCHAR(100)    NOT NULL,
    email         NVARCHAR(150)    NULL,
    phone         NVARCHAR(20)     NOT NULL,
    password_hash NVARCHAR(255)    NULL,
    role          NVARCHAR(20)     NOT NULL,  -- GUEST/CUSTOMER/MERCHANT/SHIPPER/ADMIN
    status        NVARCHAR(20)     NOT NULL CONSTRAINT DF_Users_Status DEFAULT 'ACTIVE',
    created_at    DATETIME2        NOT NULL CONSTRAINT DF_Users_Created DEFAULT SYSUTCDATETIME(),
    updated_at    DATETIME2        NOT NULL CONSTRAINT DF_Users_Updated DEFAULT SYSUTCDATETIME()
);

CREATE UNIQUE INDEX UX_Users_Phone ON dbo.Users(phone);
CREATE UNIQUE INDEX UX_Users_Email ON dbo.Users(email) WHERE email IS NOT NULL;

ALTER TABLE dbo.Users
ADD CONSTRAINT CK_Users_Role CHECK (role IN (N'GUEST',N'CUSTOMER',N'MERCHANT',N'SHIPPER',N'ADMIN'));

ALTER TABLE dbo.Users
ADD CONSTRAINT CK_Users_Status CHECK (status IN (N'ACTIVE',N'INACTIVE'));
GO

CREATE TABLE dbo.UserAuthProviders (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id          BIGINT         NOT NULL,
    provider         NVARCHAR(30)   NOT NULL, -- GOOGLE
    provider_user_id NVARCHAR(100)  NOT NULL,
    linked_at        DATETIME2      NOT NULL CONSTRAINT DF_UserAuthProviders_Linked DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_UserAuthProviders_User
        FOREIGN KEY (user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE
);

ALTER TABLE dbo.UserAuthProviders
ADD CONSTRAINT CK_UserAuthProviders_Provider CHECK (provider IN (N'GOOGLE'));

CREATE UNIQUE INDEX UX_UserAuthProviders_ProviderUser ON dbo.UserAuthProviders(provider, provider_user_id);
GO


/* =========================
   3) GUEST SESSION
   ========================= */

CREATE TABLE dbo.GuestSessions (
    guest_id      UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_GuestSessions_Id DEFAULT NEWID() PRIMARY KEY,
    contact_phone NVARCHAR(20)     NULL,
    contact_email NVARCHAR(150)    NULL,
    created_at    DATETIME2        NOT NULL CONSTRAINT DF_GuestSessions_Created DEFAULT SYSUTCDATETIME(),
    expires_at    DATETIME2        NULL
);
GO


/* =========================
   4) CUSTOMER PROFILE & ADDRESSES
   ========================= */

CREATE TABLE dbo.CustomerProfiles (
    user_id              BIGINT      NOT NULL PRIMARY KEY,
    default_address_id   BIGINT      NULL,

    food_preferences     NVARCHAR(1000) NULL,
    allergies            NVARCHAR(1000) NULL,
    health_goal          NVARCHAR(200)  NULL,
    daily_calorie_target INT            NULL,

    created_at           DATETIME2   NOT NULL CONSTRAINT DF_CustomerProfiles_Created DEFAULT SYSUTCDATETIME(),
    updated_at           DATETIME2   NOT NULL CONSTRAINT DF_CustomerProfiles_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_CustomerProfiles_User
        FOREIGN KEY (user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Addresses (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id        BIGINT        NOT NULL,

    receiver_name  NVARCHAR(100) NOT NULL,
    receiver_phone NVARCHAR(20)  NOT NULL,
    address_line   NVARCHAR(255) NOT NULL,

    province_code  NVARCHAR(20)  NOT NULL,
    province_name  NVARCHAR(100) NOT NULL,
    district_code  NVARCHAR(20)  NOT NULL,
    district_name  NVARCHAR(100) NOT NULL,
    ward_code      NVARCHAR(20)  NOT NULL,
    ward_name      NVARCHAR(100) NOT NULL,

    latitude       DECIMAL(10,7) NULL,
    longitude      DECIMAL(10,7) NULL,

    is_default     BIT           NOT NULL CONSTRAINT DF_Addresses_IsDefault DEFAULT 0,
    note           NVARCHAR(255) NULL,

    created_at     DATETIME2     NOT NULL CONSTRAINT DF_Addresses_Created DEFAULT SYSUTCDATETIME(),
    updated_at     DATETIME2     NOT NULL CONSTRAINT DF_Addresses_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Addresses_User
        FOREIGN KEY (user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE
);

CREATE INDEX IX_Addresses_User ON dbo.Addresses(user_id, is_default);
GO

ALTER TABLE dbo.CustomerProfiles
ADD CONSTRAINT FK_CustomerProfiles_DefaultAddress
    FOREIGN KEY (default_address_id) REFERENCES dbo.Addresses(id);
GO


/* =========================
   5) MERCHANT & KYC
   ========================= */

CREATE TABLE dbo.MerchantProfiles (
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

    business_hours    NVARCHAR(500)  NULL,
    avatar_url        NVARCHAR(MAX)  NULL,

    status            NVARCHAR(20)  NOT NULL CONSTRAINT DF_MerchantProfiles_Status DEFAULT 'PENDING',
    created_at        DATETIME2     NOT NULL CONSTRAINT DF_MerchantProfiles_Created DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2     NOT NULL CONSTRAINT DF_MerchantProfiles_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_MerchantProfiles_User
        FOREIGN KEY (user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE
);

ALTER TABLE dbo.MerchantProfiles
ADD CONSTRAINT CK_MerchantProfiles_Status CHECK (status IN (N'PENDING',N'APPROVED',N'REJECTED',N'SUSPENDED'));
GO

CREATE TABLE dbo.MerchantKYC (
    id                      BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id        BIGINT        NOT NULL,
    business_name           NVARCHAR(150) NOT NULL,
    business_license_number NVARCHAR(50)  NULL,
    document_url            NVARCHAR(500) NULL,

    submitted_at            DATETIME2     NOT NULL CONSTRAINT DF_MerchantKYC_Submitted DEFAULT SYSUTCDATETIME(),
    reviewed_by_admin_id    BIGINT        NULL,
    review_status           NVARCHAR(20)  NOT NULL CONSTRAINT DF_MerchantKYC_Status DEFAULT 'SUBMITTED', -- SUBMITTED/UNDER_REVIEW/APPROVED/REJECTED
    review_note             NVARCHAR(255) NULL,

    CONSTRAINT FK_MerchantKYC_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES dbo.MerchantProfiles(user_id) ON DELETE CASCADE,

    CONSTRAINT FK_MerchantKYC_Admin
        FOREIGN KEY (reviewed_by_admin_id) REFERENCES dbo.Users(id)
);

ALTER TABLE dbo.MerchantKYC
ADD CONSTRAINT CK_MerchantKYC_Status CHECK (review_status IN (N'SUBMITTED',N'UNDER_REVIEW',N'APPROVED',N'REJECTED'));
GO


/* =========================
   6) MENU: CATEGORIES & FOOD ITEMS
   ========================= */

CREATE TABLE dbo.Categories (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id BIGINT        NOT NULL,
    name             NVARCHAR(100) NOT NULL,
    is_active        BIT           NOT NULL CONSTRAINT DF_Categories_Active DEFAULT 1,
    sort_order       INT           NOT NULL CONSTRAINT DF_Categories_Sort DEFAULT 0,

    CONSTRAINT FK_Categories_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES dbo.MerchantProfiles(user_id) ON DELETE CASCADE
);
CREATE INDEX IX_Categories_Merchant ON dbo.Categories(merchant_user_id);
GO

CREATE TABLE dbo.FoodItems (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id BIGINT        NOT NULL,
    category_id      BIGINT        NOT NULL,
    name             NVARCHAR(150) NOT NULL,
    description      NVARCHAR(500) NULL,
    price            DECIMAL(18,2) NOT NULL,
    image_url        NVARCHAR(500) NULL,
    is_available     BIT           NOT NULL CONSTRAINT DF_FoodItems_Available DEFAULT 1,

    is_fried         BIT           NOT NULL CONSTRAINT DF_FoodItems_IsFried DEFAULT 0,

    calories         INT           NULL,
    protein_g        DECIMAL(10,2) NULL,
    carbs_g          DECIMAL(10,2) NULL,
    fat_g            DECIMAL(10,2) NULL,

    created_at       DATETIME2     NOT NULL CONSTRAINT DF_FoodItems_Created DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2     NOT NULL CONSTRAINT DF_FoodItems_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_FoodItems_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES dbo.MerchantProfiles(user_id) ON DELETE CASCADE,

    CONSTRAINT FK_FoodItems_Category
        FOREIGN KEY (category_id) REFERENCES dbo.Categories(id)
);

CREATE INDEX IX_FoodItems_Merchant ON dbo.FoodItems(merchant_user_id);
CREATE INDEX IX_FoodItems_Category ON dbo.FoodItems(category_id);
GO


/* =========================
   7) CARTS & CART ITEMS (single merchant)
   ========================= */

CREATE TABLE dbo.Carts (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_user_id BIGINT           NULL,
    guest_id         UNIQUEIDENTIFIER NULL,
    merchant_user_id BIGINT           NULL,
    status           NVARCHAR(20)     NOT NULL CONSTRAINT DF_Carts_Status DEFAULT 'ACTIVE', -- ACTIVE/CHECKED_OUT/ABANDONED
    created_at       DATETIME2        NOT NULL CONSTRAINT DF_Carts_Created DEFAULT SYSUTCDATETIME(),
    updated_at       DATETIME2        NOT NULL CONSTRAINT DF_Carts_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Carts_Customer FOREIGN KEY (customer_user_id) REFERENCES dbo.Users(id),
    CONSTRAINT FK_Carts_Guest    FOREIGN KEY (guest_id) REFERENCES dbo.GuestSessions(guest_id),
    CONSTRAINT FK_Carts_Merchant FOREIGN KEY (merchant_user_id) REFERENCES dbo.MerchantProfiles(user_id),

    CONSTRAINT CK_Carts_Owner CHECK (
        (customer_user_id IS NOT NULL AND guest_id IS NULL) OR
        (customer_user_id IS NULL AND guest_id IS NOT NULL)
    )
);

ALTER TABLE dbo.Carts
ADD CONSTRAINT CK_Carts_Status CHECK (status IN (N'ACTIVE',N'CHECKED_OUT',N'ABANDONED'));
GO

CREATE TABLE dbo.CartItems (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    cart_id             BIGINT        NOT NULL,
    food_item_id        BIGINT        NOT NULL,
    quantity            INT           NOT NULL,
    unit_price_snapshot DECIMAL(18,2) NOT NULL,
    note                NVARCHAR(255) NULL,

    CONSTRAINT FK_CartItems_Cart FOREIGN KEY (cart_id) REFERENCES dbo.Carts(id) ON DELETE CASCADE,
    CONSTRAINT FK_CartItems_Food FOREIGN KEY (food_item_id) REFERENCES dbo.FoodItems(id),
    CONSTRAINT CK_CartItems_Qty CHECK (quantity > 0)
);

CREATE INDEX IX_CartItems_Cart ON dbo.CartItems(cart_id);
CREATE UNIQUE INDEX UX_CartItems_CartFood ON dbo.CartItems(cart_id, food_item_id);
GO

/* Trigger enforce single merchant cart */
CREATE TRIGGER dbo.TR_CartItems_EnforceSingleMerchant
ON dbo.CartItems
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @x TABLE (
        cart_id BIGINT,
        food_item_id BIGINT,
        food_merchant BIGINT
    );

    INSERT INTO @x(cart_id, food_item_id, food_merchant)
    SELECT i.cart_id, i.food_item_id, f.merchant_user_id
    FROM inserted i
    JOIN dbo.FoodItems f ON f.id = i.food_item_id;

    UPDATE c
    SET c.merchant_user_id = x.food_merchant,
        c.updated_at = SYSUTCDATETIME()
    FROM dbo.Carts c
    JOIN @x x ON x.cart_id = c.id
    WHERE c.merchant_user_id IS NULL;

    IF EXISTS (
        SELECT 1
        FROM @x x
        JOIN dbo.Carts c ON c.id = x.cart_id
        WHERE c.merchant_user_id IS NOT NULL
          AND c.merchant_user_id <> x.food_merchant
    )
    BEGIN
        RAISERROR(N'Cart chỉ được chứa món từ 1 cửa hàng. Vui lòng tạo giỏ mới cho cửa hàng khác.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO


/* =========================
   8) ORDERS + ORDER ITEMS + STATUS HISTORY
   ========================= */

CREATE TABLE dbo.Orders (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_code          NVARCHAR(30)     NOT NULL,

    customer_user_id    BIGINT           NULL,
    guest_id            UNIQUEIDENTIFIER NULL,

    merchant_user_id    BIGINT           NOT NULL,
    shipper_user_id     BIGINT           NULL,

    receiver_name       NVARCHAR(100)    NOT NULL,
    receiver_phone      NVARCHAR(20)     NOT NULL,
    delivery_address_line NVARCHAR(255)  NOT NULL,

    province_code       NVARCHAR(20)     NOT NULL,
    province_name       NVARCHAR(100)    NOT NULL,
    district_code       NVARCHAR(20)     NOT NULL,
    district_name       NVARCHAR(100)    NOT NULL,
    ward_code           NVARCHAR(20)     NOT NULL,
    ward_name           NVARCHAR(100)    NOT NULL,

    latitude            DECIMAL(10,7)    NULL,
    longitude           DECIMAL(10,7)    NULL,
    delivery_note       NVARCHAR(255)    NULL,

    payment_method      NVARCHAR(20)     NOT NULL, -- COD/VNPAY
    payment_status      NVARCHAR(20)     NOT NULL CONSTRAINT DF_Orders_PaymentStatus DEFAULT 'UNPAID', -- UNPAID/PENDING/PAID/FAILED/REFUNDED

    order_status        NVARCHAR(30)     NOT NULL CONSTRAINT DF_Orders_OrderStatus DEFAULT 'CREATED',
    expires_at          DATETIME2        NULL,

    subtotal_amount     DECIMAL(18,2)    NOT NULL CONSTRAINT DF_Orders_Subtotal DEFAULT 0,
    delivery_fee        DECIMAL(18,2)    NOT NULL CONSTRAINT DF_Orders_DeliveryFee DEFAULT 0,
    discount_amount     DECIMAL(18,2)    NOT NULL CONSTRAINT DF_Orders_Discount DEFAULT 0,
    total_amount        DECIMAL(18,2)    NOT NULL CONSTRAINT DF_Orders_Total DEFAULT 0,

    created_at          DATETIME2        NOT NULL CONSTRAINT DF_Orders_Created DEFAULT SYSUTCDATETIME(),
    accepted_at         DATETIME2        NULL,
    ready_at            DATETIME2        NULL,
    picked_up_at        DATETIME2        NULL,
    delivered_at        DATETIME2        NULL,
    cancelled_at        DATETIME2        NULL,

    CONSTRAINT UQ_Orders_Code UNIQUE(order_code),

    CONSTRAINT FK_Orders_Customer FOREIGN KEY (customer_user_id) REFERENCES dbo.Users(id),
    CONSTRAINT FK_Orders_Guest    FOREIGN KEY (guest_id) REFERENCES dbo.GuestSessions(guest_id),
    CONSTRAINT FK_Orders_Merchant FOREIGN KEY (merchant_user_id) REFERENCES dbo.MerchantProfiles(user_id),
    CONSTRAINT FK_Orders_Shipper  FOREIGN KEY (shipper_user_id) REFERENCES dbo.Users(id),

    CONSTRAINT CK_Orders_Owner CHECK (
        (customer_user_id IS NOT NULL AND guest_id IS NULL) OR
        (customer_user_id IS NULL AND guest_id IS NOT NULL)
    )
);

ALTER TABLE dbo.Orders
ADD CONSTRAINT CK_Orders_PaymentMethod CHECK (payment_method IN (N'COD',N'VNPAY'));

ALTER TABLE dbo.Orders
ADD CONSTRAINT CK_Orders_PaymentStatus CHECK (payment_status IN (N'UNPAID',N'PENDING',N'PAID',N'FAILED',N'REFUNDED'));

ALTER TABLE dbo.Orders
ADD CONSTRAINT CK_Orders_OrderStatus CHECK (order_status IN (
    N'CREATED',
    N'PENDING_PAYMENT',
    N'PAID',
    N'MERCHANT_ACCEPTED',
    N'MERCHANT_REJECTED',
    N'PREPARING',
    N'READY_FOR_PICKUP',
    N'PICKED_UP',
    N'DELIVERING',
    N'DELIVERED',
    N'CANCELLED',
    N'FAILED',
    N'REFUNDED'
));

CREATE INDEX IX_Orders_Merchant_Status ON dbo.Orders(merchant_user_id, order_status, created_at);
CREATE INDEX IX_Orders_Shipper_Status  ON dbo.Orders(shipper_user_id, order_status, created_at);
CREATE INDEX IX_Orders_Customer_Created ON dbo.Orders(customer_user_id, created_at) WHERE customer_user_id IS NOT NULL;
GO

CREATE TABLE dbo.OrderItems (
    id                   BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id             BIGINT        NOT NULL,
    food_item_id         BIGINT        NOT NULL,
    item_name_snapshot   NVARCHAR(150) NOT NULL,
    unit_price_snapshot  DECIMAL(18,2) NOT NULL,
    quantity             INT           NOT NULL,
    note                 NVARCHAR(255) NULL,

    CONSTRAINT FK_OrderItems_Order FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Food  FOREIGN KEY (food_item_id) REFERENCES dbo.FoodItems(id),
    CONSTRAINT CK_OrderItems_Qty CHECK (quantity > 0)
);

CREATE INDEX IX_OrderItems_Order ON dbo.OrderItems(order_id);
GO

CREATE TABLE dbo.OrderStatusHistory (
    id                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id           BIGINT        NOT NULL,
    from_status        NVARCHAR(30)  NULL,
    to_status          NVARCHAR(30)  NOT NULL,
    updated_by_role    NVARCHAR(20)  NOT NULL, -- CUSTOMER/GUEST/MERCHANT/SHIPPER/ADMIN/SYSTEM
    updated_by_user_id BIGINT        NULL,
    note               NVARCHAR(255) NULL,
    created_at         DATETIME2     NOT NULL CONSTRAINT DF_OrderStatusHistory_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_OrderStatusHistory_Order FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderStatusHistory_User  FOREIGN KEY (updated_by_user_id) REFERENCES dbo.Users(id)
);

ALTER TABLE dbo.OrderStatusHistory
ADD CONSTRAINT CK_OrderStatusHistory_Role CHECK (updated_by_role IN (N'CUSTOMER',N'GUEST',N'MERCHANT',N'SHIPPER',N'ADMIN',N'SYSTEM'));

CREATE INDEX IX_OrderStatusHistory_Order ON dbo.OrderStatusHistory(order_id, created_at);
GO


/* =========================
   9) PAYMENTS (VNPAY-ready)
   ========================= */

CREATE TABLE dbo.PaymentTransactions (
    id                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id           BIGINT        NOT NULL,
    provider           NVARCHAR(20)  NOT NULL, -- VNPAY/COD
    amount             DECIMAL(18,2) NOT NULL,
    status             NVARCHAR(20)  NOT NULL, -- INITIATED/PENDING/SUCCESS/FAILED/REFUNDED
    provider_txn_ref   NVARCHAR(100) NULL,

    vnp_txn_ref        NVARCHAR(100) NULL,
    vnp_transaction_no NVARCHAR(100) NULL,
    vnp_response_code  NVARCHAR(20)  NULL,
    vnp_pay_date       NVARCHAR(50)  NULL,
    request_payload    NVARCHAR(MAX) NULL,
    callback_payload   NVARCHAR(MAX) NULL,

    created_at         DATETIME2     NOT NULL CONSTRAINT DF_PaymentTransactions_Created DEFAULT SYSUTCDATETIME(),
    updated_at         DATETIME2     NOT NULL CONSTRAINT DF_PaymentTransactions_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_PaymentTransactions_Order FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE
);

ALTER TABLE dbo.PaymentTransactions
ADD CONSTRAINT CK_PaymentTransactions_Provider CHECK (provider IN (N'VNPAY',N'COD'));

ALTER TABLE dbo.PaymentTransactions
ADD CONSTRAINT CK_PaymentTransactions_Status CHECK (status IN (N'INITIATED',N'PENDING',N'SUCCESS',N'FAILED',N'REFUNDED'));

CREATE INDEX IX_PaymentTransactions_Order ON dbo.PaymentTransactions(order_id);

CREATE UNIQUE INDEX UX_PaymentTransactions_VnpTxnRef
ON dbo.PaymentTransactions(vnp_txn_ref) WHERE vnp_txn_ref IS NOT NULL;

CREATE UNIQUE INDEX UX_PaymentTransactions_VnpTransactionNo
ON dbo.PaymentTransactions(vnp_transaction_no) WHERE vnp_transaction_no IS NOT NULL;
GO


/* =========================
   10) VOUCHERS (merchant-scoped)
   ========================= */

CREATE TABLE dbo.Vouchers (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id    BIGINT        NOT NULL,

    code                NVARCHAR(50)  NOT NULL,
    title               NVARCHAR(200) NULL,
    description         NVARCHAR(1000) NULL,

    discount_type       NVARCHAR(10)  NOT NULL, -- PERCENT/FIXED
    discount_value      DECIMAL(18,2) NOT NULL,
    max_discount_amount DECIMAL(18,2) NULL,
    min_order_amount    DECIMAL(18,2) NULL,

    start_at            DATETIME2     NOT NULL,
    end_at              DATETIME2     NOT NULL,

    max_uses_total      INT           NULL,
    max_uses_per_user   INT           NULL,

    is_published        BIT           NOT NULL CONSTRAINT DF_Vouchers_Published DEFAULT 0,
    status              NVARCHAR(20)  NOT NULL CONSTRAINT DF_Vouchers_Status DEFAULT 'ACTIVE', -- ACTIVE/INACTIVE

    created_at          DATETIME2     NOT NULL CONSTRAINT DF_Vouchers_Created DEFAULT SYSUTCDATETIME(),
    updated_at          DATETIME2     NOT NULL CONSTRAINT DF_Vouchers_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Vouchers_Merchant FOREIGN KEY (merchant_user_id) REFERENCES dbo.MerchantProfiles(user_id) ON DELETE CASCADE
);

ALTER TABLE dbo.Vouchers
ADD CONSTRAINT CK_Vouchers_DiscountType CHECK (discount_type IN (N'PERCENT',N'FIXED'));

ALTER TABLE dbo.Vouchers
ADD CONSTRAINT CK_Vouchers_Status CHECK (status IN (N'ACTIVE',N'INACTIVE'));

CREATE UNIQUE INDEX UX_Vouchers_MerchantCode ON dbo.Vouchers(merchant_user_id, code);
GO

CREATE TABLE dbo.VoucherUsages (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    voucher_id       BIGINT           NOT NULL,
    order_id         BIGINT           NOT NULL,
    customer_user_id BIGINT           NULL,
    guest_id         UNIQUEIDENTIFIER NULL,
    used_at          DATETIME2        NOT NULL CONSTRAINT DF_VoucherUsages_Used DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_VoucherUsages_Voucher FOREIGN KEY (voucher_id) REFERENCES dbo.Vouchers(id),
    CONSTRAINT FK_VoucherUsages_Order   FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_VoucherUsages_Customer FOREIGN KEY (customer_user_id) REFERENCES dbo.Users(id),
    CONSTRAINT FK_VoucherUsages_Guest FOREIGN KEY (guest_id) REFERENCES dbo.GuestSessions(guest_id),

    CONSTRAINT CK_VoucherUsages_Owner CHECK (
        (customer_user_id IS NOT NULL AND guest_id IS NULL) OR
        (customer_user_id IS NULL AND guest_id IS NOT NULL)
    )
);

CREATE UNIQUE INDEX UX_VoucherUsages_Order ON dbo.VoucherUsages(order_id);
GO


/* =========================
   11) SHIPPER + AVAILABILITY + CLAIMS
   ========================= */

CREATE TABLE dbo.ShipperProfiles (
    user_id      BIGINT       NOT NULL PRIMARY KEY,
    vehicle_type NVARCHAR(20) NOT NULL, -- MOTORBIKE/BIKE
    status       NVARCHAR(20) NOT NULL CONSTRAINT DF_ShipperProfiles_Status DEFAULT 'ACTIVE',
    created_at   DATETIME2    NOT NULL CONSTRAINT DF_ShipperProfiles_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_ShipperProfiles_User FOREIGN KEY (user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE
);

ALTER TABLE dbo.ShipperProfiles
ADD CONSTRAINT CK_ShipperProfiles_Vehicle CHECK (vehicle_type IN (N'MOTORBIKE',N'BIKE'));

ALTER TABLE dbo.ShipperProfiles
ADD CONSTRAINT CK_ShipperProfiles_Status CHECK (status IN (N'ACTIVE',N'SUSPENDED'));
GO

CREATE TABLE dbo.ShipperAvailability (
    shipper_user_id   BIGINT       NOT NULL PRIMARY KEY,
    is_online         BIT          NOT NULL CONSTRAINT DF_ShipperAvailability_Online DEFAULT 0,
    current_status    NVARCHAR(20) NOT NULL CONSTRAINT DF_ShipperAvailability_Status DEFAULT 'AVAILABLE', -- AVAILABLE/BUSY
    current_latitude  DECIMAL(10,7) NULL,
    current_longitude DECIMAL(10,7) NULL,
    updated_at        DATETIME2    NOT NULL CONSTRAINT DF_ShipperAvailability_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_ShipperAvailability_Shipper FOREIGN KEY (shipper_user_id) REFERENCES dbo.ShipperProfiles(user_id) ON DELETE CASCADE
);

ALTER TABLE dbo.ShipperAvailability
ADD CONSTRAINT CK_ShipperAvailability_Status CHECK (current_status IN (N'AVAILABLE',N'BUSY'));

CREATE INDEX IX_ShipperAvailability_Filter ON dbo.ShipperAvailability(is_online, current_status);
GO

CREATE TABLE dbo.OrderClaims (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id        BIGINT       NOT NULL,
    shipper_user_id BIGINT       NOT NULL,
    status          NVARCHAR(20) NOT NULL, -- CLAIMED/CONFIRMED/EXPIRED/CANCELLED
    claimed_at      DATETIME2    NOT NULL CONSTRAINT DF_OrderClaims_Claimed DEFAULT SYSUTCDATETIME(),
    expires_at      DATETIME2    NOT NULL,
    confirmed_at    DATETIME2    NULL,

    CONSTRAINT FK_OrderClaims_Order FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderClaims_Shipper FOREIGN KEY (shipper_user_id) REFERENCES dbo.Users(id)
);

ALTER TABLE dbo.OrderClaims
ADD CONSTRAINT CK_OrderClaims_Status CHECK (status IN (N'CLAIMED',N'CONFIRMED',N'EXPIRED',N'CANCELLED'));

CREATE UNIQUE INDEX UX_OrderClaims_ActiveOrder
ON dbo.OrderClaims(order_id)
WHERE status IN (N'CLAIMED',N'CONFIRMED');
GO


/* =========================
   12) DELIVERY ISSUES + ADMIN RESOLUTION
   ========================= */

CREATE TABLE dbo.DeliveryIssues (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id        BIGINT       NOT NULL,
    shipper_user_id BIGINT       NOT NULL,
    issue_type     NVARCHAR(30)  NOT NULL, -- NO_ANSWER/WRONG_ADDRESS/REFUSED/WAIT_TOO_LONG/OTHER
    attempts_count INT           NOT NULL CONSTRAINT DF_DeliveryIssues_Attempts DEFAULT 0,
    note           NVARCHAR(255) NULL,
    created_at     DATETIME2     NOT NULL CONSTRAINT DF_DeliveryIssues_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_DeliveryIssues_Order FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_DeliveryIssues_Shipper FOREIGN KEY (shipper_user_id) REFERENCES dbo.Users(id)
);
GO

CREATE TABLE dbo.FailedDeliveryResolutions (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id             BIGINT       NOT NULL,
    handled_by_admin_id  BIGINT       NOT NULL,
    resolution_type     NVARCHAR(30)  NOT NULL, -- RETRY/CANCEL/RETURNED/DISPOSED
    note                NVARCHAR(255) NULL,
    created_at          DATETIME2     NOT NULL CONSTRAINT DF_FailedDeliveryResolutions_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_FailedDeliveryResolutions_Order FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_FailedDeliveryResolutions_Admin FOREIGN KEY (handled_by_admin_id) REFERENCES dbo.Users(id)
);
GO


/* =========================
   13) RATINGS
   ========================= */

CREATE TABLE dbo.Ratings (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id          BIGINT           NOT NULL,
    rater_customer_id BIGINT           NULL,
    rater_guest_id    UNIQUEIDENTIFIER NULL,
    target_type       NVARCHAR(20)     NOT NULL, -- MERCHANT/SHIPPER
    target_user_id    BIGINT           NOT NULL,
    stars             INT              NOT NULL,
    comment           NVARCHAR(500)    NULL,
    created_at        DATETIME2        NOT NULL CONSTRAINT DF_Ratings_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Ratings_Order FOREIGN KEY (order_id) REFERENCES dbo.Orders(id) ON DELETE CASCADE,
    CONSTRAINT FK_Ratings_RaterCustomer FOREIGN KEY (rater_customer_id) REFERENCES dbo.Users(id),
    CONSTRAINT FK_Ratings_RaterGuest FOREIGN KEY (rater_guest_id) REFERENCES dbo.GuestSessions(guest_id),
    CONSTRAINT FK_Ratings_TargetUser FOREIGN KEY (target_user_id) REFERENCES dbo.Users(id),

    CONSTRAINT CK_Ratings_Rater CHECK (
        (rater_customer_id IS NOT NULL AND rater_guest_id IS NULL) OR
        (rater_customer_id IS NULL AND rater_guest_id IS NOT NULL)
    ),
    CONSTRAINT CK_Ratings_TargetType CHECK (target_type IN (N'MERCHANT',N'SHIPPER')),
    CONSTRAINT CK_Ratings_Stars CHECK (stars BETWEEN 1 AND 5)
);

CREATE UNIQUE INDEX UX_Ratings_OrderTarget ON dbo.Ratings(order_id, target_type);
GO


/* =========================
   14) USER BEHAVIOR EVENTS + NOTIFICATIONS
   ========================= */

CREATE TABLE dbo.UserBehaviorEvents (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_user_id BIGINT           NULL,
    guest_id         UNIQUEIDENTIFIER NULL,
    event_type       NVARCHAR(30)     NOT NULL, -- VIEW_ITEM/SEARCH/ADD_TO_CART/ORDER_PLACED
    food_item_id     BIGINT           NULL,
    keyword          NVARCHAR(200)    NULL,
    created_at       DATETIME2        NOT NULL CONSTRAINT DF_UserBehaviorEvents_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_UserBehaviorEvents_Customer FOREIGN KEY (customer_user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE,
    CONSTRAINT FK_UserBehaviorEvents_Guest FOREIGN KEY (guest_id) REFERENCES dbo.GuestSessions(guest_id),
    CONSTRAINT FK_UserBehaviorEvents_Food FOREIGN KEY (food_item_id) REFERENCES dbo.FoodItems(id),

    CONSTRAINT CK_UserBehaviorEvents_Owner CHECK (
        (customer_user_id IS NOT NULL AND guest_id IS NULL) OR
        (customer_user_id IS NULL AND guest_id IS NOT NULL)
    )
);

CREATE INDEX IX_UserBehaviorEvents_Customer ON dbo.UserBehaviorEvents(customer_user_id, created_at) WHERE customer_user_id IS NOT NULL;
CREATE INDEX IX_UserBehaviorEvents_Guest ON dbo.UserBehaviorEvents(guest_id, created_at) WHERE guest_id IS NOT NULL;
GO

CREATE TABLE dbo.Notifications (
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id    BIGINT           NULL,
    guest_id   UNIQUEIDENTIFIER NULL,
    type       NVARCHAR(50)     NOT NULL,
    content    NVARCHAR(500)    NOT NULL,
    is_read    BIT              NOT NULL CONSTRAINT DF_Notifications_Read DEFAULT 0,
    created_at DATETIME2        NOT NULL CONSTRAINT DF_Notifications_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_Notifications_User FOREIGN KEY (user_id) REFERENCES dbo.Users(id),
    CONSTRAINT FK_Notifications_Guest FOREIGN KEY (guest_id) REFERENCES dbo.GuestSessions(guest_id),

    CONSTRAINT CK_Notifications_Target CHECK (
        (user_id IS NOT NULL AND guest_id IS NULL) OR
        (user_id IS NULL AND guest_id IS NOT NULL)
    )
);

CREATE INDEX IX_Notifications_User ON dbo.Notifications(user_id, is_read, created_at) WHERE user_id IS NOT NULL;
CREATE INDEX IX_Notifications_Guest ON dbo.Notifications(guest_id, is_read, created_at) WHERE guest_id IS NOT NULL;
GO


/* =========================
   15) AI CHAT + AUTO-CART
   ========================= */

CREATE TABLE dbo.AIConversations (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_user_id BIGINT    NOT NULL,
    created_at       DATETIME2 NOT NULL CONSTRAINT DF_AIConversations_Created DEFAULT SYSUTCDATETIME(),
    last_activity_at DATETIME2 NOT NULL CONSTRAINT DF_AIConversations_Last DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_AIConversations_Customer
        FOREIGN KEY (customer_user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.AIMessages (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    conversation_id BIGINT        NOT NULL,
    role            NVARCHAR(20)  NOT NULL, -- USER/ASSISTANT/SYSTEM
    content         NVARCHAR(MAX) NOT NULL,
    created_at      DATETIME2     NOT NULL CONSTRAINT DF_AIMessages_Created DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_AIMessages_Conversation
        FOREIGN KEY (conversation_id) REFERENCES dbo.AIConversations(id) ON DELETE CASCADE,

    CONSTRAINT CK_AIMessages_Role CHECK (role IN (N'USER',N'ASSISTANT',N'SYSTEM'))
);
GO

/* IMPORTANT: Merchant FK is NO ACTION to avoid multiple cascade paths */
CREATE TABLE dbo.AutoCartProposals (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_user_id BIGINT        NOT NULL,
    merchant_user_id BIGINT        NOT NULL,
    conversation_id  BIGINT        NULL,
    status           NVARCHAR(20)  NOT NULL CONSTRAINT DF_AutoCartProposals_Status DEFAULT 'PROPOSED',
    created_at       DATETIME2     NOT NULL CONSTRAINT DF_AutoCartProposals_Created DEFAULT SYSUTCDATETIME(),
    expires_at       DATETIME2     NULL,

    CONSTRAINT FK_AutoCartProposals_Customer
        FOREIGN KEY (customer_user_id) REFERENCES dbo.Users(id) ON DELETE CASCADE,

    CONSTRAINT FK_AutoCartProposals_Merchant
        FOREIGN KEY (merchant_user_id) REFERENCES dbo.MerchantProfiles(user_id) ON DELETE NO ACTION,

    CONSTRAINT FK_AutoCartProposals_Conversation
        FOREIGN KEY (conversation_id) REFERENCES dbo.AIConversations(id) ON DELETE NO ACTION,

    CONSTRAINT CK_AutoCartProposals_Status CHECK (status IN (N'PROPOSED',N'CONFIRMED',N'REJECTED',N'EXPIRED'))
);
GO

CREATE TABLE dbo.AutoCartProposalItems (
    id           BIGINT IDENTITY(1,1) PRIMARY KEY,
    proposal_id  BIGINT        NOT NULL,
    food_item_id BIGINT        NOT NULL,
    quantity     INT           NOT NULL,
    unit_price   DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_AutoCartProposalItems_Proposal
        FOREIGN KEY (proposal_id) REFERENCES dbo.AutoCartProposals(id) ON DELETE CASCADE,

    CONSTRAINT FK_AutoCartProposalItems_Food
        FOREIGN KEY (food_item_id) REFERENCES dbo.FoodItems(id),

    CONSTRAINT CK_AutoCartProposalItems_Qty CHECK (quantity > 0)
);

CREATE UNIQUE INDEX UX_AutoCartProposalItems_ProposalFood ON dbo.AutoCartProposalItems(proposal_id, food_item_id);
GO


/* =========================
   16) WITHDRAWAL REQUESTS
   ========================= */

CREATE TABLE dbo.WithdrawalRequests (
    id                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    merchant_user_id   BIGINT          NOT NULL
        REFERENCES dbo.Users(id) ON DELETE CASCADE,
    amount             DECIMAL(18,2)   NOT NULL,
    bank_name          NVARCHAR(100)   NOT NULL,
    bank_account       NVARCHAR(50)    NOT NULL,
    account_holder     NVARCHAR(100)   NOT NULL,
    status             NVARCHAR(20)    NOT NULL DEFAULT N'PENDING',
    note               NVARCHAR(500)   NULL,
    created_at         DATETIME2       NOT NULL DEFAULT SYSUTCDATETIME(),
    processed_at       DATETIME2       NULL,
    CONSTRAINT CHK_withdrawal_status
        CHECK (status IN (N'PENDING', N'APPROVED', N'REJECTED', N'COMPLETED'))
);

CREATE INDEX IX_withdrawal_merchant ON dbo.WithdrawalRequests(merchant_user_id);
GO


/* =========================================================
   17) SEED DATA (no GO inside this block)
   ========================================================= */

BEGIN TRY
    BEGIN TRAN;

    /* ---- Users ---- */
    -- Tất cả tài khoản dùng mật khẩu: 123456  (bcrypt $2a$, cost=10, verified với jBCrypt 0.4)
    DECLARE @pw NVARCHAR(255) = N'$2a$10$yO60YX1uH.jQiJg0z7cmD.aLwgjWsQ7TbYCglZuidaE2SvAOYW/Z2';
    INSERT INTO dbo.Users(full_name,email,phone,password_hash,role,status)
    VALUES
    (N'Admin ClickEat',      N'admin@clickeat.vn',     N'0900000001', @pw, N'ADMIN',   N'ACTIVE'),
    (N'Merchant 1',          N'merchant1@shop.vn',     N'0900000002', @pw, N'MERCHANT',N'ACTIVE'),
    (N'Merchant 2',          N'merchant2@shop.vn',     N'0900000003', @pw, N'MERCHANT',N'ACTIVE'),
    (N'Merchant 3',          N'merchant3@shop.vn',     N'0900000004', @pw, N'MERCHANT',N'ACTIVE'),
    (N'Merchant 4',          N'merchant4@shop.vn',     N'0900000005', @pw, N'MERCHANT',N'ACTIVE'),
    (N'Merchant 5',          N'merchant5@shop.vn',     N'0900000006', @pw, N'MERCHANT',N'ACTIVE'),
    (N'Shipper 1',           N'shipper1@clickeat.vn',  N'0900000007', @pw, N'SHIPPER', N'ACTIVE'),
    (N'Shipper 2',           N'shipper2@clickeat.vn',  N'0900000008', @pw, N'SHIPPER', N'ACTIVE'),
    (N'Shipper 3',           N'shipper3@clickeat.vn',  N'0900000009', @pw, N'SHIPPER', N'ACTIVE'),
    (N'Shipper 4',           N'shipper4@clickeat.vn',  N'0900000010', @pw, N'SHIPPER', N'ACTIVE'),
    (N'Shipper 5',           N'shipper5@clickeat.vn',  N'0900000011', @pw, N'SHIPPER', N'ACTIVE'),
    (N'Customer 1',          N'customer1@clickeat.vn', N'0900000012', @pw, N'CUSTOMER',N'ACTIVE'),
    (N'Customer 2',          N'customer2@clickeat.vn', N'0900000013', @pw, N'CUSTOMER',N'ACTIVE'),
    (N'Customer 3',          N'customer3@clickeat.vn', N'0900000014', @pw, N'CUSTOMER',N'ACTIVE'),
    (N'Customer 4',          N'customer4@clickeat.vn', N'0900000015', @pw, N'CUSTOMER',N'ACTIVE'),
    (N'Customer 5',          N'customer5@clickeat.vn', N'0900000016', @pw, N'CUSTOMER',N'ACTIVE');

    DECLARE @admin BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000001');
    DECLARE @m1 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000002');
    DECLARE @m2 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000003');
    DECLARE @m3 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000004');
    DECLARE @m4 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000005');
    DECLARE @m5 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000006');

    DECLARE @s1 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000007');
    DECLARE @s2 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000008');
    DECLARE @s3 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000009');
    DECLARE @s4 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000010');
    DECLARE @s5 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000011');

    DECLARE @c1 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000012');
    DECLARE @c2 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000013');
    DECLARE @c3 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000014');
    DECLARE @c4 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000015');
    DECLARE @c5 BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000016');

    /* ---- Google providers for 5 customers ---- */
    INSERT INTO dbo.UserAuthProviders(user_id,provider,provider_user_id)
    VALUES
    (@c1,N'GOOGLE',N'google-sub-c1'),
    (@c2,N'GOOGLE',N'google-sub-c2'),
    (@c3,N'GOOGLE',N'google-sub-c3'),
    (@c4,N'GOOGLE',N'google-sub-c4'),
    (@c5,N'GOOGLE',N'google-sub-c5');

    /* ---- Guests ---- */
    DECLARE @g1 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g2 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g3 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g4 UNIQUEIDENTIFIER = NEWID();
    DECLARE @g5 UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.GuestSessions(guest_id,contact_phone,contact_email,expires_at)
    VALUES
    (@g1,N'0987000001',N'guest1@mail.com',DATEADD(DAY,7,SYSUTCDATETIME())),
    (@g2,N'0987000002',N'guest2@mail.com',DATEADD(DAY,7,SYSUTCDATETIME())),
    (@g3,N'0987000003',N'guest3@mail.com',DATEADD(DAY,7,SYSUTCDATETIME())),
    (@g4,N'0987000004',N'guest4@mail.com',DATEADD(DAY,7,SYSUTCDATETIME())),
    (@g5,N'0987000005',N'guest5@mail.com',DATEADD(DAY,7,SYSUTCDATETIME()));

    /* ---- Customer profiles ---- */
    INSERT INTO dbo.CustomerProfiles(user_id,food_preferences,allergies,health_goal,daily_calorie_target)
    VALUES
    (@c1,N'Ít dầu, thích cay vừa, nhiều rau', N'Hải sản', N'Giữ dáng', 2000),
    (@c2,N'Thích combo, không ăn quá cay', NULL, N'Tăng cân nhẹ', 2400),
    (@c3,N'Ưu tiên món nướng, hạn chế đồ chiên', NULL, N'Tăng cơ', 2600),
    (@c4,N'Ăn thanh đạm, ít muối', NULL, N'Sức khỏe', 1900),
    (@c5,N'Không ăn ngọt, thích nước không đường', NULL, N'Giảm mỡ', 2100);

    /* ---- Addresses ---- */
    INSERT INTO dbo.Addresses
    (user_id,receiver_name,receiver_phone,address_line,province_code,province_name,district_code,district_name,ward_code,ward_name,latitude,longitude,is_default,note)
    VALUES
    (@c1,N'Huy', N'0900000012', N'12 Nguyễn Huệ',      N'79',N'TP.HCM',N'760',N'Quận 1',     N'26734',N'Bến Nghé',   10.77653,106.70098,1,N'Gọi trước khi giao'),
    (@c2,N'Lan', N'0900000013', N'34 Lê Lợi',          N'79',N'TP.HCM',N'760',N'Quận 1',     N'26737',N'Bến Thành',  10.77216,106.69817,1,NULL),
    (@c3,N'Minh',N'0900000014', N'88 Điện Biên Phủ',   N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',  10.80520,106.71290,1,N'Để lễ tân'),
    (@c4,N'Nga', N'0900000015', N'15 Võ Văn Ngân',     N'79',N'TP.HCM',N'762',N'Thủ Đức',   N'26848',N'Linh Chiểu', 10.85140,106.75790,1,NULL),
    (@c5,N'Phúc',N'0900000016', N'20 Nguyễn Văn Linh', N'48',N'Đà Nẵng',N'490',N'Hải Châu', N'20194',N'Phước Ninh', 16.06060,108.22220,1,N'Giao giờ trưa');

    UPDATE dbo.CustomerProfiles SET default_address_id = (SELECT TOP 1 id FROM dbo.Addresses WHERE user_id=@c1 AND is_default=1) WHERE user_id=@c1;
    UPDATE dbo.CustomerProfiles SET default_address_id = (SELECT TOP 1 id FROM dbo.Addresses WHERE user_id=@c2 AND is_default=1) WHERE user_id=@c2;
    UPDATE dbo.CustomerProfiles SET default_address_id = (SELECT TOP 1 id FROM dbo.Addresses WHERE user_id=@c3 AND is_default=1) WHERE user_id=@c3;
    UPDATE dbo.CustomerProfiles SET default_address_id = (SELECT TOP 1 id FROM dbo.Addresses WHERE user_id=@c4 AND is_default=1) WHERE user_id=@c4;
    UPDATE dbo.CustomerProfiles SET default_address_id = (SELECT TOP 1 id FROM dbo.Addresses WHERE user_id=@c5 AND is_default=1) WHERE user_id=@c5;

    /* ---- Merchant profiles ---- */
    INSERT INTO dbo.MerchantProfiles
    (user_id,shop_name,shop_phone,shop_address_line,province_code,province_name,district_code,district_name,ward_code,ward_name,latitude,longitude,status)
    VALUES
    (@m1,N'Lollibee Q1', N'0280000002', N'10 Đồng Khởi',          N'79',N'TP.HCM',N'760',N'Quận 1',     N'26734',N'Bến Nghé',   10.77500,106.70400,N'APPROVED'),
    (@m2,N'Lollibee Q3', N'0280000003', N'250 CMT8',              N'79',N'TP.HCM',N'770',N'Quận 3',     N'27349',N'Phường 10',  10.78400,106.68000,N'APPROVED'),
    (@m3,N'Lollibee BT', N'0280000004', N'120 Xô Viết Nghệ Tĩnh', N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',  10.80400,106.71300,N'APPROVED'),
    (@m4,N'Lollibee TD', N'0280000005', N'5 Kha Vạn Cân',         N'79',N'TP.HCM',N'762',N'Thủ Đức',   N'26848',N'Linh Chiểu', 10.85000,106.75800,N'PENDING'),
    (@m5,N'Lollibee DN', N'0236000006', N'99 Nguyễn Văn Linh',    N'48',N'Đà Nẵng',N'490',N'Hải Châu', N'20194',N'Phước Ninh', 16.06000,108.22200,N'PENDING');

    /* ---- Business hours (default: MON-SAT 09:00-22:00, SUN closed) ---- */
    UPDATE dbo.MerchantProfiles
    SET business_hours = N'[{"day":"MON","open":true,"from":"09:00","to":"22:00"},{"day":"TUE","open":true,"from":"09:00","to":"22:00"},{"day":"WED","open":true,"from":"09:00","to":"22:00"},{"day":"THU","open":true,"from":"09:00","to":"22:00"},{"day":"FRI","open":true,"from":"09:00","to":"22:00"},{"day":"SAT","open":true,"from":"09:00","to":"22:00"},{"day":"SUN","open":false,"from":"09:00","to":"22:00"}]'
    WHERE business_hours IS NULL;

    /* ---- Merchant KYC ---- */
    INSERT INTO dbo.MerchantKYC(merchant_user_id,business_name,business_license_number,document_url,reviewed_by_admin_id,review_status,review_note)
    VALUES
    (@m1,N'Hộ KD Lollibee Q1',N'GP-001',N'https://example.com/kyc/m1.pdf',@admin,N'APPROVED',N'OK'),
    (@m2,N'Hộ KD Lollibee Q3',N'GP-002',N'https://example.com/kyc/m2.pdf',@admin,N'APPROVED',N'OK'),
    (@m3,N'Hộ KD Lollibee BT',N'GP-003',N'https://example.com/kyc/m3.pdf',@admin,N'UNDER_REVIEW',N'Đang kiểm tra'),
    (@m4,N'Hộ KD Lollibee TD',NULL,     N'https://example.com/kyc/m4.pdf',@admin,N'SUBMITTED',NULL),
    (@m5,N'Hộ KD Lollibee DN',NULL,     N'https://example.com/kyc/m5.pdf',@admin,N'REJECTED',N'Thiếu thông tin (resubmit được)');

    /* ---- Categories ---- */
    INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order)
    VALUES
    (@m1,N'Gà rán',1,1),
    (@m2,N'Combo',1,1),
    (@m3,N'Burger',1,1),
    (@m4,N'Đồ uống',1,1),
    (@m5,N'Tráng miệng',1,1);

    DECLARE @cat_m1 BIGINT = (SELECT TOP 1 id FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Gà rán');
    DECLARE @cat_m2 BIGINT = (SELECT TOP 1 id FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Combo');
    DECLARE @cat_m3 BIGINT = (SELECT TOP 1 id FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Burger');
    DECLARE @cat_m4 BIGINT = (SELECT TOP 1 id FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Đồ uống');
    DECLARE @cat_m5 BIGINT = (SELECT TOP 1 id FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Tráng miệng');

    /* ---- Food items (10) ---- */
    INSERT INTO dbo.FoodItems(merchant_user_id,category_id,name,description,price,image_url,is_available,is_fried,calories,protein_g,carbs_g,fat_g)
    VALUES
    (@m1,@cat_m1,N'Gà rán giòn',N'Gà rán truyền thống',45000,NULL,1,1,520,28,35,22),
    (@m1,@cat_m1,N'Gà cay',     N'Gà rán sốt cay',     50000,NULL,1,1,560,30,38,24),
    (@m2,@cat_m2,N'Combo 1',    N'Gà + khoai + nước',  79000,NULL,1,1,850,35,95,30),
    (@m2,@cat_m2,N'Combo 2',    N'Gà + burger + nước', 89000,NULL,1,1,980,40,110,35),
    (@m3,@cat_m3,N'Burger gà',  N'Burger gà giòn',     55000,NULL,1,1,650,26,70,25),
    (@m3,@cat_m3,N'Burger cá',  N'Burger cá',          52000,NULL,1,0,540,22,60,18),
    (@m4,@cat_m4,N'Trà đào',    N'Nước uống',          30000,NULL,1,0,140,0,35,0),
    (@m4,@cat_m4,N'Coca',       N'Nước uống',          20000,NULL,1,0,150,0,39,0),
    (@m5,@cat_m5,N'Kem vani',   N'Tráng miệng',        25000,NULL,1,0,210,4,24,10),
    (@m5,@cat_m5,N'Bánh flan',  N'Tráng miệng',        22000,NULL,1,0,180,6,22,6);

    DECLARE @fi1 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Gà rán giòn');
    DECLARE @fi2 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Gà cay');
    DECLARE @fi3 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Combo 1');
    DECLARE @fi4 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Combo 2');
    DECLARE @fi5 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Burger gà');
    DECLARE @fi6 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Burger cá');
    DECLARE @fi7 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Trà đào');
    DECLARE @fi9 BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE name=N'Kem vani');

    /* ---- Carts (3 customer + 2 guest) ---- */
    INSERT INTO dbo.Carts(customer_user_id,guest_id,merchant_user_id,status)
    VALUES
    (@c1,NULL,@m1,N'ACTIVE'),
    (@c2,NULL,@m2,N'ACTIVE'),
    (@c3,NULL,@m4,N'ACTIVE'),
    (NULL,@g1,@m3,N'ACTIVE'),
    (NULL,@g2,@m5,N'ACTIVE');

    DECLARE @cart1 BIGINT = (SELECT MIN(id) FROM dbo.Carts WHERE customer_user_id=@c1);
    DECLARE @cart2 BIGINT = (SELECT MIN(id) FROM dbo.Carts WHERE customer_user_id=@c2);
    DECLARE @cart3 BIGINT = (SELECT MIN(id) FROM dbo.Carts WHERE customer_user_id=@c3);
    DECLARE @cart4 BIGINT = (SELECT MIN(id) FROM dbo.Carts WHERE guest_id=@g1);
    DECLARE @cart5 BIGINT = (SELECT MIN(id) FROM dbo.Carts WHERE guest_id=@g2);

    /* ---- CartItems ---- */
    INSERT INTO dbo.CartItems(cart_id,food_item_id,quantity,unit_price_snapshot,note)
    VALUES
    (@cart1,@fi1,2,45000,NULL),
    (@cart2,@fi3,1,79000,N'Ít đá'),
    (@cart3,@fi7,2,30000,NULL),
    (@cart4,@fi5,1,55000,NULL),
    (@cart5,@fi9,3,25000,N'Giao nhanh');

    /* ---- Shipper profiles + availability ---- */
    INSERT INTO dbo.ShipperProfiles(user_id,vehicle_type,status)
    VALUES
    (@s1,N'MOTORBIKE',N'ACTIVE'),
    (@s2,N'MOTORBIKE',N'ACTIVE'),
    (@s3,N'MOTORBIKE',N'ACTIVE'),
    (@s4,N'BIKE',N'ACTIVE'),
    (@s5,N'MOTORBIKE',N'ACTIVE');

    INSERT INTO dbo.ShipperAvailability(shipper_user_id,is_online,current_status,current_latitude,current_longitude)
    VALUES
    (@s1,1,N'BUSY',10.7760,106.7010),
    (@s2,1,N'BUSY',10.7725,106.6985),
    (@s3,1,N'AVAILABLE',10.7758,106.7002),
    (@s4,1,N'AVAILABLE',10.8050,106.7135),
    (@s5,0,N'AVAILABLE',NULL,NULL);

    /* ---- Orders (5) ---- */
    INSERT INTO dbo.Orders
    (order_code,customer_user_id,guest_id,merchant_user_id,shipper_user_id,
     receiver_name,receiver_phone,delivery_address_line,
     province_code,province_name,district_code,district_name,ward_code,ward_name,
     latitude,longitude,delivery_note,
     payment_method,payment_status,order_status,expires_at,
     subtotal_amount,delivery_fee,discount_amount,total_amount,
     accepted_at,ready_at,picked_up_at,delivered_at,cancelled_at)
    VALUES
    (N'ORD0001',@c1,NULL,@m1,@s1,
     N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',
     10.77653,106.70098,N'Gọi trước',
     N'COD',N'PAID',N'DELIVERED',NULL,
     90000,15000,0,105000,
     DATEADD(MINUTE,-40,SYSUTCDATETIME()),DATEADD(MINUTE,-30,SYSUTCDATETIME()),DATEADD(MINUTE,-25,SYSUTCDATETIME()),DATEADD(MINUTE,-5,SYSUTCDATETIME()),NULL),

    (N'ORD0002',@c2,NULL,@m2,@s2,
     N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',
     10.77216,106.69817,NULL,
     N'VNPAY',N'PAID',N'DELIVERING',NULL,
     79000,15000,5000,89000,
     DATEADD(MINUTE,-25,SYSUTCDATETIME()),DATEADD(MINUTE,-15,SYSUTCDATETIME()),DATEADD(MINUTE,-10,SYSUTCDATETIME()),NULL,NULL),

    (N'ORD0003',@c3,NULL,@m3,NULL,
     N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',
     10.80520,106.71290,N'Để lễ tân',
     N'COD',N'UNPAID',N'READY_FOR_PICKUP',NULL,
     55000,12000,0,67000,
     DATEADD(MINUTE,-20,SYSUTCDATETIME()),DATEADD(MINUTE,-5,SYSUTCDATETIME()),NULL,NULL,NULL),

    (N'ORD0004',NULL,@g1,@m1,@s3,
     N'Guest 1',N'0987000001',N'100 Lý Tự Trọng',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',
     10.77590,106.70010,NULL,
     N'COD',N'UNPAID',N'FAILED',NULL,
     50000,15000,0,65000,
     DATEADD(MINUTE,-35,SYSUTCDATETIME()),DATEADD(MINUTE,-25,SYSUTCDATETIME()),DATEADD(MINUTE,-15,SYSUTCDATETIME()),NULL,NULL),

    (N'ORD0005',NULL,@g2,@m2,NULL,
     N'Guest 2',N'0987000002',N'50 Pasteur',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',
     10.77180,106.69900,N'Hủy nếu chờ lâu',
     N'VNPAY',N'FAILED',N'CANCELLED',DATEADD(MINUTE,15,SYSUTCDATETIME()),
     89000,15000,0,104000,
     NULL,NULL,NULL,NULL,SYSUTCDATETIME());

    DECLARE @o1 BIGINT = (SELECT id FROM dbo.Orders WHERE order_code=N'ORD0001');
    DECLARE @o2 BIGINT = (SELECT id FROM dbo.Orders WHERE order_code=N'ORD0002');
    DECLARE @o3 BIGINT = (SELECT id FROM dbo.Orders WHERE order_code=N'ORD0003');
    DECLARE @o4 BIGINT = (SELECT id FROM dbo.Orders WHERE order_code=N'ORD0004');
    DECLARE @o5 BIGINT = (SELECT id FROM dbo.Orders WHERE order_code=N'ORD0005');

    /* ---- OrderItems ---- */
    INSERT INTO dbo.OrderItems(order_id,food_item_id,item_name_snapshot,unit_price_snapshot,quantity,note)
    VALUES
    (@o1,@fi1,N'Gà rán giòn',45000,2,NULL),
    (@o2,@fi3,N'Combo 1',79000,1,NULL),
    (@o3,@fi5,N'Burger gà',55000,1,NULL),
    (@o4,@fi2,N'Gà cay',50000,1,NULL),
    (@o5,@fi4,N'Combo 2',89000,1,NULL);

    /* ---- Status history ---- */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note)
    VALUES
    (@o1,NULL,N'CREATED',N'CUSTOMER',@c1,NULL),
    (@o1,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m1,NULL),
    (@o1,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m1,NULL),
    (@o1,N'PREPARING',N'READY_FOR_PICKUP',N'MERCHANT',@m1,NULL),
    (@o1,N'READY_FOR_PICKUP',N'PICKED_UP',N'SHIPPER',@s1,NULL),
    (@o1,N'PICKED_UP',N'DELIVERED',N'SHIPPER',@s1,NULL),

    (@o4,NULL,N'CREATED',N'GUEST',NULL,NULL),
    (@o4,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m1,NULL),
    (@o4,N'MERCHANT_ACCEPTED',N'DELIVERING',N'SHIPPER',@s3,NULL),
    (@o4,N'DELIVERING',N'FAILED',N'SHIPPER',@s3,N'No answer');

    /* ---- Payments ---- */
    INSERT INTO dbo.PaymentTransactions(order_id,provider,amount,status,provider_txn_ref,vnp_txn_ref,vnp_transaction_no,vnp_response_code,vnp_pay_date,callback_payload)
    VALUES
    (@o1,N'COD', 105000,N'SUCCESS',NULL,NULL,NULL,NULL,NULL,NULL),
    (@o2,N'VNPAY',89000,N'SUCCESS',N'VNPAY-TXN-0002',N'ORD0002',N'1234567890',N'00',N'20260225160000',N'{"vnp_ResponseCode":"00"}'),
    (@o3,N'COD',  67000,N'INITIATED',NULL,NULL,NULL,NULL,NULL,NULL),
    (@o4,N'COD',  65000,N'FAILED',NULL,NULL,NULL,NULL,NULL,NULL),
    (@o5,N'VNPAY',104000,N'FAILED',N'VNPAY-TXN-0005',N'ORD0005',NULL,N'99',NULL,N'{"vnp_ResponseCode":"99"}');

    /* ---- Vouchers ---- */
    INSERT INTO dbo.Vouchers
    (merchant_user_id,code,title,description,discount_type,discount_value,max_discount_amount,min_order_amount,start_at,end_at,max_uses_total,max_uses_per_user,is_published,status)
    VALUES
    (@m1,N'CLICK5', N'Giảm 5k',  N'Giảm 5k cho đơn từ 50k', N'FIXED',   5000, NULL, 50000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,30,SYSUTCDATETIME()), 500,2,1,N'ACTIVE'),
    (@m2,N'CLICK10',N'Giảm 10%', N'Giảm 10% tối đa 20k',    N'PERCENT', 10,   20000,80000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,30,SYSUTCDATETIME()), 300,1,1,N'ACTIVE'),
    (@m3,N'FRYFREE',N'Giảm 10k', N'Giảm 10k cho đơn từ 90k',N'FIXED',   10000,NULL, 90000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,10,SYSUTCDATETIME()), 200,1,1,N'ACTIVE'),
    (@m4,N'NEWUSER',N'Giảm 15k', N'Giảm 15k cho đơn từ 70k',N'FIXED',   15000,NULL, 70000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,20,SYSUTCDATETIME()), 100,1,1,N'ACTIVE'),
    (@m5,N'WEEKEND',N'Giảm 5%',  N'Giảm 5% cuối tuần',      N'PERCENT', 5,    15000,40000, DATEADD(DAY,-1,SYSUTCDATETIME()), DATEADD(DAY,60,SYSUTCDATETIME()), 999,3,0,N'INACTIVE');

    DECLARE @v1 BIGINT = (SELECT id FROM dbo.Vouchers WHERE merchant_user_id=@m1 AND code=N'CLICK5');
    DECLARE @v2 BIGINT = (SELECT id FROM dbo.Vouchers WHERE merchant_user_id=@m2 AND code=N'CLICK10');
    DECLARE @v3 BIGINT = (SELECT id FROM dbo.Vouchers WHERE merchant_user_id=@m3 AND code=N'FRYFREE');
    DECLARE @v4 BIGINT = (SELECT id FROM dbo.Vouchers WHERE merchant_user_id=@m4 AND code=N'NEWUSER');
    DECLARE @v5 BIGINT = (SELECT id FROM dbo.Vouchers WHERE merchant_user_id=@m5 AND code=N'WEEKEND');

    INSERT INTO dbo.VoucherUsages(voucher_id,order_id,customer_user_id,guest_id)
    VALUES
    (@v2,@o2,@c2,NULL),
    (@v1,@o1,@c1,NULL),
    (@v3,@o3,@c3,NULL),
    (@v4,@o4,NULL,@g1),
    (@v5,@o5,NULL,@g2);

    /* ---- Delivery issues + resolutions ---- */
    INSERT INTO dbo.DeliveryIssues(order_id,shipper_user_id,issue_type,attempts_count,note)
    VALUES
    (@o4,@s3,N'NO_ANSWER',3,N'Khách không nghe máy'),
    (@o2,@s2,N'WRONG_ADDRESS',1,N'Địa chỉ thiếu số nhà'),
    (@o1,@s1,N'OTHER',0,N'Giao trễ do kẹt xe'),
    (@o4,@s3,N'WAIT_TOO_LONG',1,N'Chờ 10 phút không gặp'),
    (@o5,@s4,N'NO_ANSWER',2,N'Khách bận');

    INSERT INTO dbo.FailedDeliveryResolutions(order_id,handled_by_admin_id,resolution_type,note)
    VALUES
    (@o4,@admin,N'CANCEL',N'Giao thất bại - hủy đơn'),
    (@o2,@admin,N'RETRY',N'Liên hệ khách cập nhật địa chỉ'),
    (@o1,@admin,N'RETURNED',N'Ghi nhận hoàn về (demo)'),
    (@o5,@admin,N'CANCEL',N'Thanh toán thất bại - hủy'),
    (@o3,@admin,N'RETRY',N'Chờ shipper nhận đơn');

    /* ---- Ratings ---- */
    INSERT INTO dbo.Ratings(order_id,rater_customer_id,rater_guest_id,target_type,target_user_id,stars,comment)
    VALUES
    (@o1,@c1,NULL,N'SHIPPER',@s1,5,N'Giao nhanh, thân thiện'),
    (@o1,@c1,NULL,N'MERCHANT',@m1,4,N'Đồ ăn ngon'),
    (@o2,@c2,NULL,N'MERCHANT',@m2,5,N'Combo ổn, đóng gói tốt'),
    (@o4,NULL,@g1,N'SHIPPER',@s3,2,N'Gọi không được'),
    (@o5,NULL,@g2,N'MERCHANT',@m2,3,N'Đặt không thành công');

    /* ---- Behavior events ---- */
    INSERT INTO dbo.UserBehaviorEvents(customer_user_id,guest_id,event_type,food_item_id,keyword)
    VALUES
    (@c1,NULL,N'VIEW_ITEM',@fi1,NULL),
    (@c2,NULL,N'SEARCH',NULL,N'combo'),
    (@c3,NULL,N'ADD_TO_CART',@fi5,NULL),
    (NULL,@g1,N'VIEW_ITEM',@fi2,NULL),
    (NULL,@g2,N'ORDER_PLACED',@fi3,NULL);

    /* ---- Notifications ---- */
    INSERT INTO dbo.Notifications(user_id,guest_id,type,content,is_read)
    VALUES
    (@c1,NULL,N'ORDER_CONFIRMED',N'Đơn ORD0001 đã được xác nhận.',1),
    (@c2,NULL,N'STATUS_CHANGED', N'Đơn ORD0002 đang được giao.',0),
    (NULL,@g1,N'FAILED',         N'Đơn ORD0004 giao thất bại. Vui lòng liên hệ hỗ trợ.',0),
    (@m1,NULL,N'NEW_ORDER',      N'Bạn có đơn hàng mới ORD0003.',0),
    (@s1,NULL,N'ASSIGNED_ORDER', N'Bạn được gán đơn ORD0001.',1);

    /* ---- OrderClaims demo ---- */
    INSERT INTO dbo.OrderClaims(order_id,shipper_user_id,status,expires_at)
    VALUES
    (@o3,@s3,N'CLAIMED',DATEADD(SECOND,60,SYSUTCDATETIME()));

    /* ---- WithdrawalRequests for merchant 1 ---- */
    INSERT INTO dbo.WithdrawalRequests
        (merchant_user_id, amount, bank_name, bank_account, account_holder, status, created_at, processed_at)
    VALUES
    (@m1, 5000000,  N'Vietcombank',   N'1234567890',  N'NGUYEN VAN A', N'COMPLETED', '2026-02-01 10:00:00', '2026-02-02 09:00:00'),
    (@m1, 3000000,  N'Techcombank',   N'9876543210',  N'NGUYEN VAN A', N'COMPLETED', '2026-02-14 15:00:00', '2026-02-15 08:00:00'),
    (@m1, 8000000,  N'Vietcombank',   N'1234567890',  N'NGUYEN VAN A', N'PENDING',   '2026-03-02 11:00:00', NULL);

    /* ---- AI chat + Auto-cart ---- */
    INSERT INTO dbo.AIConversations(customer_user_id) VALUES (@c1);
    DECLARE @conv BIGINT = SCOPE_IDENTITY();

    INSERT INTO dbo.AIMessages(conversation_id,role,content)
    VALUES
    (@conv,N'USER',N'Mình muốn ăn ít dầu và hạn chế đồ chiên, gợi ý giúp.'),
    (@conv,N'ASSISTANT',N'Bạn có thể thử Burger cá hoặc Trà đào. Mình có thể thêm vào giỏ nếu bạn đồng ý.');

    INSERT INTO dbo.AutoCartProposals(customer_user_id,merchant_user_id,conversation_id,status,expires_at)
    VALUES (@c1,@m3,@conv,N'PROPOSED',DATEADD(MINUTE,10,SYSUTCDATETIME()));

    DECLARE @proposal BIGINT = SCOPE_IDENTITY();

    INSERT INTO dbo.AutoCartProposalItems(proposal_id,food_item_id,quantity,unit_price)
    VALUES
    (@proposal,@fi6,1,52000),
    (@proposal,@fi7,1,30000);

    COMMIT TRAN;
    PRINT N'✅ ClickEat: CREATE + SEED completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    PRINT N'❌ ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO

/* =========================================================
   CLICKEAT — EXTRA SEED DATA (Additive, run after main SQL)
   - Thêm 4 category + 12 món ăn mới cho merchant1
   - 50 đơn hàng trải đều 30 ngày qua (cho Analytics / Wallet)
   - Ratings, Notifications, Vouchers phong phú
   ========================================================= */
SET NOCOUNT ON;
USE ClickEat;
GO

BEGIN TRY
    BEGIN TRAN;

    /* ── Lấy lại user IDs ────────────────────────────── */
    DECLARE @m1   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000002');
    DECLARE @c1   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000012');
    DECLARE @c2   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000013');
    DECLARE @c3   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000014');
    DECLARE @c4   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000015');
    DECLARE @c5   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000016');
    DECLARE @s1   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000007');
    DECLARE @s2   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000008');
    DECLARE @s3   BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000009');
    DECLARE @admin BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000001');

    /* ── Kategori mới cho merchant1 ─────────────────── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Burger & Sandwich')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m1,N'Burger & Sandwich',1,2);

    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Khoai & Món phụ')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m1,N'Khoai & Món phụ',1,3);

    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Đồ uống')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m1,N'Đồ uống',1,4);

    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Combo')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m1,N'Combo',1,5);

    DECLARE @cat_burger  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Burger & Sandwich');
    DECLARE @cat_khoai   BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Khoai & Món phụ');
    DECLARE @cat_drink   BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Đồ uống');
    DECLARE @cat_combo   BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Combo');
    DECLARE @cat_ga      BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m1 AND name=N'Gà rán');

    /* ── Món ăn mới cho merchant1 ────────────────────── */
    IF NOT EXISTS (SELECT 1 FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Burger Zinger')
        INSERT INTO dbo.FoodItems(merchant_user_id,category_id,name,description,price,is_available,is_fried,calories,protein_g,carbs_g,fat_g)
        VALUES
        (@m1,@cat_burger,N'Burger Zinger',        N'Burger gà cay giòn với sốt đặc biệt',         65000,1,1,710,31,72,28),
        (@m1,@cat_burger,N'Burger Phô Mai',        N'Burger gà phủ phô mai Cheddar tan chảy',      70000,1,1,760,34,75,32),
        (@m1,@cat_burger,N'Burger Cá Giòn',        N'Cá tươi tẩm bột chiên giòn',                 62000,1,1,620,26,65,22),
        (@m1,@cat_khoai, N'Khoai Tây Chiên Nhỏ',  N'Khoai tây vàng giòn, bột gia vị đặc biệt',   25000,1,1,360,5,45,17),
        (@m1,@cat_khoai, N'Khoai Tây Chiên Lớn',  N'Khoai tây khổ lớn',                          35000,1,1,490,7,62,23),
        (@m1,@cat_khoai, N'Salad Kem',             N'Rau củ tươi sốt kem nhẹ',                    28000,1,0,180,4,14,10),
        (@m1,@cat_drink, N'Pepsi',                 N'Nước ngọt lạnh',                             18000,1,0,147,0,38,0),
        (@m1,@cat_drink, N'Pepsi Zero',            N'Không đường – không calories',                18000,1,0,0,0,0,0),
        (@m1,@cat_drink, N'Trà Chanh Đào',         N'Trà đào tươi mát pha chanh',                 25000,1,0,130,0,32,0),
        (@m1,@cat_combo, N'Combo 1 Người',         N'1 Gà rán + Khoai nhỏ + Pepsi',               75000,1,1,1020,33,118,39),
        (@m1,@cat_combo, N'Combo 2 Người',         N'2 Gà rán + Khoai lớn + 2 Pepsi',             145000,1,1,1830,61,213,79),
        (@m1,@cat_combo, N'Combo Gia Đình',        N'4 Gà rán + 2 Khoai lớn + 4 Pepsi + Salad',  250000,1,1,3600,122,424,156);

    /* ── Lấy food item IDs ───────────────────────────── */
    DECLARE @fi_ga1   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Gà rán giòn');
    DECLARE @fi_ga2   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Gà cay');
    DECLARE @fi_bz    BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Burger Zinger');
    DECLARE @fi_bpm   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Burger Phô Mai');
    DECLARE @fi_bca   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Burger Cá Giòn');
    DECLARE @fi_ks    BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Khoai Tây Chiên Nhỏ');
    DECLARE @fi_kl    BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Khoai Tây Chiên Lớn');
    DECLARE @fi_pep   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Pepsi');
    DECLARE @fi_tra   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Trà Chanh Đào');
    DECLARE @fi_cb1   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Combo 1 Người');
    DECLARE @fi_cb2   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Combo 2 Người');
    DECLARE @fi_cbf   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Combo Gia Đình');
    DECLARE @fi_sal   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Salad Kem');

    /* ── Thêm voucher cho merchant1 ──────────────────── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Vouchers WHERE merchant_user_id=@m1 AND code=N'LOLI20')
    INSERT INTO dbo.Vouchers(merchant_user_id,code,title,description,discount_type,discount_value,max_discount_amount,min_order_amount,start_at,end_at,max_uses_total,max_uses_per_user,is_published,status)
    VALUES
    (@m1,N'LOLI20',  N'Giảm 20k',          N'Áp dụng cho đơn từ 120k',            N'FIXED',  20000,NULL,   120000,DATEADD(DAY,-5,SYSUTCDATETIME()),DATEADD(DAY,25,SYSUTCDATETIME()),200,2,1,N'ACTIVE'),
    (@m1,N'LOLI15',  N'Giảm 15%',          N'Tối đa 30k, đơn từ 80k',             N'PERCENT',15,   30000, 80000, DATEADD(DAY,-3,SYSUTCDATETIME()),DATEADD(DAY,14,SYSUTCDATETIME()),100,1,1,N'ACTIVE'),
    (@m1,N'BIRTHDAY',N'Sinh nhật -25k',    N'Ưu đãi sinh nhật tháng 3',           N'FIXED',  25000,NULL,   150000,DATEADD(DAY,-1,SYSUTCDATETIME()),DATEADD(DAY, 7,SYSUTCDATETIME()), 50,1,1,N'ACTIVE'),
    (@m1,N'EARLYBIRD',N'Sáng sớm -10%',   N'Đặt trước 9h giảm 10%, tối đa 15k',  N'PERCENT',10,   15000, 50000, DATEADD(DAY,-7,SYSUTCDATETIME()),DATEADD(DAY,30,SYSUTCDATETIME()),500,5,0,N'INACTIVE');

    /* ── 50 đơn hàng cho merchant1 trải 30 ngày ─────── */
    /* Helper: tất cả đơn thuộc merchant1, khách xoay vòng c1-c5 */

    INSERT INTO dbo.Orders
    (order_code,customer_user_id,guest_id,merchant_user_id,shipper_user_id,
     receiver_name,receiver_phone,delivery_address_line,
     province_code,province_name,district_code,district_name,ward_code,ward_name,
     latitude,longitude,delivery_note,payment_method,payment_status,order_status,expires_at,
     subtotal_amount,delivery_fee,discount_amount,total_amount,
     accepted_at,ready_at,picked_up_at,delivered_at,cancelled_at)
    VALUES
    /* ── Tuần này (ngày -0 → -6) ── */
    (N'M1-D0-001',@c1,NULL,@m1,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     DATEADD(HOUR,-2,SYSUTCDATETIME()),DATEADD(MINUTE,-100,SYSUTCDATETIME()),DATEADD(MINUTE,-90,SYSUTCDATETIME()),DATEADD(MINUTE,-65,SYSUTCDATETIME()),NULL),

    (N'M1-D0-002',@c2,NULL,@m1,@s2,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,N'Ít đá',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(HOUR,-4,SYSUTCDATETIME()),DATEADD(HOUR,-3,SYSUTCDATETIME()),DATEADD(MINUTE,-170,SYSUTCDATETIME()),DATEADD(MINUTE,-150,SYSUTCDATETIME()),NULL),

    (N'M1-D0-003',@c3,NULL,@m1,@s1,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,20000,250000,
     DATEADD(HOUR,-6,SYSUTCDATETIME()),DATEADD(HOUR,-5,SYSUTCDATETIME()),DATEADD(MINUTE,-285,SYSUTCDATETIME()),DATEADD(MINUTE,-260,SYSUTCDATETIME()),NULL),

    (N'M1-D0-004',@c4,NULL,@m1,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'COD',N'UNPAID',N'PREPARING',NULL,
     65000,15000,0,80000,
     DATEADD(MINUTE,-30,SYSUTCDATETIME()),NULL,NULL,NULL,NULL),

    (N'M1-D1-001',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,15000,145000,
     DATEADD(DAY,-1,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-1,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-1,DATEADD(HOUR,3,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-1,DATEADD(HOUR,3,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D1-002',@c1,NULL,@m1,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-1,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-1,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-1,DATEADD(HOUR,7,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-1,DATEADD(HOUR,7,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D1-003',@c2,NULL,@m1,@s3,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     130000,15000,20000,125000,
     DATEADD(DAY,-1,DATEADD(HOUR,10,SYSUTCDATETIME())),DATEADD(DAY,-1,DATEADD(HOUR,11,SYSUTCDATETIME())),DATEADD(DAY,-1,DATEADD(HOUR,11,DATEADD(MINUTE,10,SYSUTCDATETIME()))),DATEADD(DAY,-1,DATEADD(HOUR,11,DATEADD(MINUTE,40,SYSUTCDATETIME()))),NULL),

    (N'M1-D1-004',@c3,NULL,@m1,NULL,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     65000,15000,0,80000,
     NULL,NULL,NULL,NULL,DATEADD(DAY,-1,DATEADD(HOUR,12,SYSUTCDATETIME()))),

    (N'M1-D2-001',@c4,NULL,@m1,@s2,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,0,270000,
     DATEADD(DAY,-2,DATEADD(HOUR,1,SYSUTCDATETIME())),DATEADD(DAY,-2,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-2,DATEADD(HOUR,2,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-2,DATEADD(HOUR,2,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D2-002',@c5,NULL,@m1,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     70000,15000,0,85000,
     DATEADD(DAY,-2,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-2,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-2,DATEADD(HOUR,6,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-2,DATEADD(HOUR,6,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D2-003',@c1,NULL,@m1,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     DATEADD(DAY,-2,DATEADD(HOUR,9,SYSUTCDATETIME())),DATEADD(DAY,-2,DATEADD(HOUR,10,SYSUTCDATETIME())),DATEADD(DAY,-2,DATEADD(HOUR,10,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-2,DATEADD(HOUR,10,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D3-001',@c2,NULL,@m1,@s2,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-3,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-3,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-3,DATEADD(HOUR,3,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-3,DATEADD(HOUR,3,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D3-002',@c3,NULL,@m1,@s1,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     195000,15000,25000,185000,
     DATEADD(DAY,-3,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-3,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-3,DATEADD(HOUR,7,DATEADD(MINUTE,25,SYSUTCDATETIME()))),DATEADD(DAY,-3,DATEADD(HOUR,7,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D3-003',@c4,NULL,@m1,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     65000,15000,0,80000,
     NULL,NULL,NULL,NULL,DATEADD(DAY,-3,DATEADD(HOUR,8,SYSUTCDATETIME()))),

    (N'M1-D4-001',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     130000,15000,0,145000,
     DATEADD(DAY,-4,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-4,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-4,DATEADD(HOUR,4,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-4,DATEADD(HOUR,4,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D4-002',@c1,NULL,@m1,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,N'Gọi trước',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-4,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-4,DATEADD(HOUR,8,SYSUTCDATETIME())),DATEADD(DAY,-4,DATEADD(HOUR,8,DATEADD(MINUTE,10,SYSUTCDATETIME()))),DATEADD(DAY,-4,DATEADD(HOUR,8,DATEADD(MINUTE,40,SYSUTCDATETIME()))),NULL),

    (N'M1-D5-001',@c2,NULL,@m1,@s3,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,20000,250000,
     DATEADD(DAY,-5,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-5,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-5,DATEADD(HOUR,3,DATEADD(MINUTE,25,SYSUTCDATETIME()))),DATEADD(DAY,-5,DATEADD(HOUR,3,DATEADD(MINUTE,60,SYSUTCDATETIME()))),NULL),

    (N'M1-D5-002',@c3,NULL,@m1,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     DATEADD(DAY,-5,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-5,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-5,DATEADD(HOUR,7,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-5,DATEADD(HOUR,7,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D6-001',@c4,NULL,@m1,@s1,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-6,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-6,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-6,DATEADD(HOUR,5,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-6,DATEADD(HOUR,5,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    /* ── Tuần 2 (ngày -7 → -13) ── */
    (N'M1-D7-001',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     DATEADD(DAY,-7,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-7,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-7,DATEADD(HOUR,3,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-7,DATEADD(HOUR,3,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D7-002',@c1,NULL,@m1,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     65000,15000,0,80000,
     DATEADD(DAY,-7,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-7,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-7,DATEADD(HOUR,7,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-7,DATEADD(HOUR,7,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D8-001',@c2,NULL,@m1,@s1,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     250000,20000,25000,245000,
     DATEADD(DAY,-8,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-8,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-8,DATEADD(HOUR,4,DATEADD(MINUTE,25,SYSUTCDATETIME()))),DATEADD(DAY,-8,DATEADD(HOUR,5,SYSUTCDATETIME())),NULL),

    (N'M1-D8-002',@c3,NULL,@m1,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     75000,15000,0,90000,
     NULL,NULL,NULL,NULL,DATEADD(DAY,-8,DATEADD(HOUR,5,SYSUTCDATETIME()))),

    (N'M1-D9-001',@c4,NULL,@m1,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     130000,15000,0,145000,
     DATEADD(DAY,-9,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-9,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-9,DATEADD(HOUR,3,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-9,DATEADD(HOUR,3,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D9-002',@c5,NULL,@m1,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-9,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-9,DATEADD(HOUR,8,SYSUTCDATETIME())),DATEADD(DAY,-9,DATEADD(HOUR,8,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-9,DATEADD(HOUR,8,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D10-001',@c1,NULL,@m1,@s2,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     195000,15000,20000,190000,
     DATEADD(DAY,-10,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-10,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-10,DATEADD(HOUR,5,DATEADD(MINUTE,25,SYSUTCDATETIME()))),DATEADD(DAY,-10,DATEADD(HOUR,6,SYSUTCDATETIME())),NULL),

    (N'M1-D10-002',@c2,NULL,@m1,NULL,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     65000,15000,0,80000,
     NULL,NULL,NULL,NULL,DATEADD(DAY,-10,DATEADD(HOUR,6,SYSUTCDATETIME()))),

    (N'M1-D11-001',@c3,NULL,@m1,@s3,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-11,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-11,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-11,DATEADD(HOUR,3,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-11,DATEADD(HOUR,3,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D12-001',@c4,NULL,@m1,@s1,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     DATEADD(DAY,-12,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-12,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-12,DATEADD(HOUR,6,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-12,DATEADD(HOUR,6,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D13-001',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     250000,20000,0,270000,
     DATEADD(DAY,-13,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-13,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-13,DATEADD(HOUR,4,DATEADD(MINUTE,25,SYSUTCDATETIME()))),DATEADD(DAY,-13,DATEADD(HOUR,5,SYSUTCDATETIME())),NULL),

    /* ── Tuần 3-4 (ngày -14 → -29) ── */
    (N'M1-D14-001',@c1,NULL,@m1,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-14,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-14,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-14,DATEADD(HOUR,5,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-14,DATEADD(HOUR,5,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D15-001',@c2,NULL,@m1,@s1,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     130000,15000,0,145000,
     DATEADD(DAY,-15,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-15,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-15,DATEADD(HOUR,4,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-15,DATEADD(HOUR,4,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D16-001',@c3,NULL,@m1,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     195000,15000,15000,195000,
     DATEADD(DAY,-16,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-16,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-16,DATEADD(HOUR,6,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-16,DATEADD(HOUR,6,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D17-001',@c4,NULL,@m1,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     65000,15000,0,80000,
     DATEADD(DAY,-17,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-17,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-17,DATEADD(HOUR,3,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-17,DATEADD(HOUR,3,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D18-001',@c5,NULL,@m1,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-18,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-18,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-18,DATEADD(HOUR,7,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-18,DATEADD(HOUR,7,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D18-002',@c1,NULL,@m1,@s2,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     250000,20000,0,270000,
     NULL,NULL,NULL,NULL,DATEADD(DAY,-18,DATEADD(HOUR,8,SYSUTCDATETIME()))),

    (N'M1-D19-001',@c2,NULL,@m1,@s3,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     DATEADD(DAY,-19,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-19,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-19,DATEADD(HOUR,4,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-19,DATEADD(HOUR,4,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D20-001',@c3,NULL,@m1,@s1,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-20,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-20,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-20,DATEADD(HOUR,6,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-20,DATEADD(HOUR,6,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D21-001',@c4,NULL,@m1,@s2,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,20000,250000,
     DATEADD(DAY,-21,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-21,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-21,DATEADD(HOUR,3,DATEADD(MINUTE,25,SYSUTCDATETIME()))),DATEADD(DAY,-21,DATEADD(HOUR,4,SYSUTCDATETIME())),NULL),

    (N'M1-D22-001',@c5,NULL,@m1,@s3,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     130000,15000,0,145000,
     DATEADD(DAY,-22,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-22,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-22,DATEADD(HOUR,5,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-22,DATEADD(HOUR,5,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D23-001',@c1,NULL,@m1,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-23,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-23,DATEADD(HOUR,7,SYSUTCDATETIME())),DATEADD(DAY,-23,DATEADD(HOUR,7,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-23,DATEADD(HOUR,7,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D24-001',@c2,NULL,@m1,@s2,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     195000,15000,0,210000,
     DATEADD(DAY,-24,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-24,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-24,DATEADD(HOUR,4,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-24,DATEADD(HOUR,4,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D25-001',@c3,NULL,@m1,@s3,N'Minh',N'0900000014',N'88 Điện Biên Phủ',N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     DATEADD(DAY,-25,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-25,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-25,DATEADD(HOUR,6,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-25,DATEADD(HOUR,6,DATEADD(MINUTE,50,SYSUTCDATETIME()))),NULL),

    (N'M1-D26-001',@c4,NULL,@m1,@s1,N'Nga',N'0900000015',N'15 Võ Văn Ngân',N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-26,DATEADD(HOUR,2,SYSUTCDATETIME())),DATEADD(DAY,-26,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-26,DATEADD(HOUR,3,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-26,DATEADD(HOUR,3,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL),

    (N'M1-D27-001',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,25000,245000,
     DATEADD(DAY,-27,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-27,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-27,DATEADD(HOUR,5,DATEADD(MINUTE,25,SYSUTCDATETIME()))),DATEADD(DAY,-27,DATEADD(HOUR,6,SYSUTCDATETIME())),NULL),

    (N'M1-D28-001',@c1,NULL,@m1,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     130000,15000,0,145000,
     DATEADD(DAY,-28,DATEADD(HOUR,3,SYSUTCDATETIME())),DATEADD(DAY,-28,DATEADD(HOUR,4,SYSUTCDATETIME())),DATEADD(DAY,-28,DATEADD(HOUR,4,DATEADD(MINUTE,20,SYSUTCDATETIME()))),DATEADD(DAY,-28,DATEADD(HOUR,4,DATEADD(MINUTE,55,SYSUTCDATETIME()))),NULL),

    (N'M1-D29-001',@c2,NULL,@m1,@s1,N'Lan',N'0900000013',N'34 Lê Lợi',N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     DATEADD(DAY,-29,DATEADD(HOUR,5,SYSUTCDATETIME())),DATEADD(DAY,-29,DATEADD(HOUR,6,SYSUTCDATETIME())),DATEADD(DAY,-29,DATEADD(HOUR,6,DATEADD(MINUTE,15,SYSUTCDATETIME()))),DATEADD(DAY,-29,DATEADD(HOUR,6,DATEADD(MINUTE,45,SYSUTCDATETIME()))),NULL);

    /* ── OrderItems cho tất cả đơn mới ────────────────── */
    INSERT INTO dbo.OrderItems(order_id,food_item_id,item_name_snapshot,unit_price_snapshot,quantity,note)
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D0-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D0-002' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D0-003' UNION ALL
    SELECT o.id, @fi_bz,  N'Burger Zinger',  65000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D0-004' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D1-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D1-002' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, N'Ít đá' FROM dbo.Orders o WHERE o.order_code=N'M1-D1-003' UNION ALL
    SELECT o.id, @fi_bz,  N'Burger Zinger',  65000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D1-004' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D2-001' UNION ALL
    SELECT o.id, @fi_bpm, N'Burger Phô Mai', 70000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D2-002' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D2-003' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D3-001' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D3-002' UNION ALL
    SELECT o.id, @fi_bz,  N'Burger Zinger',  65000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D3-003' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D4-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D4-002' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D5-001' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D5-002' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D6-001' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D7-001' UNION ALL
    SELECT o.id, @fi_bz,  N'Burger Zinger',  65000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D7-002' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D8-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D8-002' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D9-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D9-002' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D10-001' UNION ALL
    SELECT o.id, @fi_bz,  N'Burger Zinger',  65000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D10-002' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D11-001' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D12-001' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D13-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D14-001' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D15-001' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D16-001' UNION ALL
    SELECT o.id, @fi_bz,  N'Burger Zinger',  65000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D17-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D18-001' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D18-002' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D19-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D20-001' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D21-001' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D22-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D23-001' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D24-001' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D25-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D26-001' UNION ALL
    SELECT o.id, @fi_cbf, N'Combo Gia Đình',250000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D27-001' UNION ALL
    SELECT o.id, @fi_cb2, N'Combo 2 Người', 145000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D28-001' UNION ALL
    SELECT o.id, @fi_cb1, N'Combo 1 Người',  75000, 1, NULL FROM dbo.Orders o WHERE o.order_code=N'M1-D29-001';

    /* thêm 1 item phụ cho một số đơn lớn */
    INSERT INTO dbo.OrderItems(order_id,food_item_id,item_name_snapshot,unit_price_snapshot,quantity,note)
    SELECT o.id, @fi_kl, N'Khoai Tây Chiên Lớn', 35000, 1, NULL FROM dbo.Orders o WHERE o.order_code IN (N'M1-D3-002',N'M1-D16-001',N'M1-D24-001') UNION ALL
    SELECT o.id, @fi_pep,N'Pepsi', 18000, 2, NULL FROM dbo.Orders o WHERE o.order_code IN (N'M1-D5-001',N'M1-D10-001',N'M1-D21-001') UNION ALL
    SELECT o.id, @fi_ga1,N'Gà rán giòn', 45000, 1, NULL FROM dbo.Orders o WHERE o.order_code IN (N'M1-D13-001',N'M1-D27-001');

    /* ── Status history cho các đơn DELIVERED mới ──── */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,
           DATEADD(MINUTE,-5,o.accepted_at)
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m1,NULL,
           o.accepted_at
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m1,NULL,
           DATEADD(MINUTE,3,o.accepted_at)
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PREPARING',N'READY_FOR_PICKUP',N'MERCHANT',@m1,NULL,
           o.ready_at
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'READY_FOR_PICKUP',N'PICKED_UP',N'SHIPPER',o.shipper_user_id,NULL,
           o.picked_up_at
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PICKED_UP',N'DELIVERED',N'SHIPPER',o.shipper_user_id,NULL,
           o.delivered_at
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'DELIVERED';

    /* status history cho các đơn CANCELLED */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,
           DATEADD(MINUTE,-2,o.cancelled_at)
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'CANCELLED'
    UNION ALL
    SELECT o.id,N'CREATED',N'CANCELLED',N'CUSTOMER',o.customer_user_id,N'Khách huỷ đơn',
           o.cancelled_at
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'CANCELLED';

    /* status history cho đơn PREPARING */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,DATEADD(MINUTE,-35,SYSUTCDATETIME())
    FROM dbo.Orders o WHERE o.order_code=N'M1-D0-004'
    UNION ALL
    SELECT o.id,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m1,NULL,DATEADD(MINUTE,-33,SYSUTCDATETIME())
    FROM dbo.Orders o WHERE o.order_code=N'M1-D0-004'
    UNION ALL
    SELECT o.id,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m1,NULL,o.accepted_at
    FROM dbo.Orders o WHERE o.order_code=N'M1-D0-004';

    /* ── PaymentTransactions cho các đơn mới ─────── */
    INSERT INTO dbo.PaymentTransactions(order_id,provider,amount,status,created_at)
    SELECT o.id,
           o.payment_method,
           o.total_amount,
           CASE WHEN o.order_status=N'DELIVERED' THEN N'SUCCESS'
                WHEN o.order_status=N'CANCELLED' THEN N'FAILED'
                ELSE N'INITIATED' END,
           o.created_at
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%';

    /* ── Ratings / Reviews cho các đơn DELIVERED ── */
    INSERT INTO dbo.Ratings(order_id,rater_customer_id,rater_guest_id,target_type,target_user_id,stars,comment,created_at)
    SELECT o.id,o.customer_user_id,NULL,N'MERCHANT',@m1,
           CASE (o.id % 5)
               WHEN 0 THEN 5 WHEN 1 THEN 5 WHEN 2 THEN 4
               WHEN 3 THEN 4 ELSE 3 END,
           CASE (o.id % 8)
               WHEN 0 THEN N'Đồ ăn tươi ngon, giao đúng giờ!'
               WHEN 1 THEN N'Combo gia đình quá đáng tiền, cả nhà đều thích'
               WHEN 2 THEN N'Gà giòn, không bị nguội khi nhận'
               WHEN 3 THEN N'Đóng gói cẩn thận, sẽ đặt lại'
               WHEN 4 THEN N'Shipper nhiệt tình, đồ ăn đúng yêu cầu'
               WHEN 5 THEN N'Burger phô mai siêu ngon, highly recommend'
               WHEN 6 THEN N'Giao hơi lâu nhưng đồ ăn ngon bù lại'
               ELSE      N'Ổn, hài lòng với đơn hàng' END,
           DATEADD(MINUTE,30,o.delivered_at)
    FROM dbo.Orders o
    WHERE o.merchant_user_id=@m1
      AND o.order_code LIKE N'M1-%'
      AND o.order_status=N'DELIVERED'
      AND NOT EXISTS (SELECT 1 FROM dbo.Ratings r WHERE r.order_id=o.id AND r.target_type=N'MERCHANT');

    /* ── Notifications cho merchant1 ─────────────── */
    INSERT INTO dbo.Notifications(user_id,guest_id,type,content,is_read,created_at)
    VALUES
    (@m1,NULL,N'ORDER_NEW',      N'Đơn hàng M1-D0-004 vừa được đặt. Tổng: 80,000đ',   0, DATEADD(MINUTE,-32,SYSUTCDATETIME())),
    (@m1,NULL,N'ORDER_NEW',      N'Đơn hàng M1-D0-001 vừa được đặt. Tổng: 160,000đ',  1, DATEADD(HOUR,-2,SYSUTCDATETIME())),
    (@m1,NULL,N'ORDER_NEW',      N'Đơn hàng M1-D0-002 vừa được đặt. Tổng: 90,000đ',   1, DATEADD(HOUR,-4,SYSUTCDATETIME())),
    (@m1,NULL,N'ORDER_NEW',      N'Đơn hàng M1-D0-003 vừa được đặt. Tổng: 250,000đ',  1, DATEADD(HOUR,-6,SYSUTCDATETIME())),
    (@m1,NULL,N'REVIEW',         N'Khách hàng vừa đánh giá 5⭐ cho cửa hàng của bạn',  0, DATEADD(HOUR,-1,SYSUTCDATETIME())),
    (@m1,NULL,N'REVIEW',         N'Khách hàng vừa đánh giá 4⭐: "Đồ ăn ngon đóng gói cẩn thận"', 0, DATEADD(HOUR,-3,SYSUTCDATETIME())),
    (@m1,NULL,N'SYSTEM',         N'Voucher BIRTHDAY của bạn sẽ hết hạn trong 7 ngày',  0, DATEADD(DAY,-1,SYSUTCDATETIME())),
    (@m1,NULL,N'SYSTEM',         N'Doanh thu tháng 3 đã vượt 5 triệu đồng. Chúc mừng!',0,DATEADD(DAY,-2,SYSUTCDATETIME())),
    (@m1,NULL,N'ORDER_CANCELLED',N'Đơn M1-D1-004 đã bị huỷ bởi khách hàng',            1, DATEADD(DAY,-1,DATEADD(HOUR,12,SYSUTCDATETIME()))),
    (@m1,NULL,N'ORDER_DELIVERED',N'Đơn M1-D1-001 đã giao thành công (145,000đ)',        1, DATEADD(DAY,-1,DATEADD(HOUR,4,SYSUTCDATETIME())));

    COMMIT TRAN;

    /* ── Tóm tắt dữ liệu đã thêm ─────────────────── */
    DECLARE @cnt_cat   INT;
    DECLARE @cnt_food  INT;
    DECLARE @cnt_ord   INT;
    DECLARE @cnt_dlv   INT;
    DECLARE @cnt_can   INT;
    DECLARE @cnt_rat   INT;
    DECLARE @cnt_noti  INT;
    DECLARE @sum_rev   DECIMAL(18,2);

    SELECT @cnt_cat  = COUNT(*) FROM dbo.Categories  WHERE merchant_user_id = @m1;
    SELECT @cnt_food = COUNT(*) FROM dbo.FoodItems   WHERE merchant_user_id = @m1;
    SELECT @cnt_ord  = COUNT(*) FROM dbo.Orders      WHERE merchant_user_id = @m1;
    SELECT @cnt_dlv  = COUNT(*) FROM dbo.Orders      WHERE merchant_user_id = @m1 AND order_status = N'DELIVERED';
    SELECT @cnt_can  = COUNT(*) FROM dbo.Orders      WHERE merchant_user_id = @m1 AND order_status = N'CANCELLED';
    SELECT @sum_rev  = ISNULL(SUM(total_amount), 0)  FROM dbo.Orders WHERE merchant_user_id = @m1 AND order_status = N'DELIVERED';
    SELECT @cnt_rat  = COUNT(*) FROM dbo.Ratings r JOIN dbo.Orders o ON o.id = r.order_id WHERE o.merchant_user_id = @m1;
    SELECT @cnt_noti = COUNT(*) FROM dbo.Notifications WHERE user_id = @m1;

    PRINT N'✅ SEED EXTRA completed!';
    PRINT N'   + Categories merchant1: '        + CAST(@cnt_cat  AS NVARCHAR(20));
    PRINT N'   + Food items merchant1: '        + CAST(@cnt_food AS NVARCHAR(20));
    PRINT N'   + Orders merchant1 (all): '      + CAST(@cnt_ord  AS NVARCHAR(20));
    PRINT N'   + DELIVERED orders: '            + CAST(@cnt_dlv  AS NVARCHAR(20));
    PRINT N'   + CANCELLED orders: '            + CAST(@cnt_can  AS NVARCHAR(20));
    PRINT N'   + Total revenue (DELIVERED): '   + CAST(@sum_rev  AS NVARCHAR(30));
    PRINT N'   + Ratings: '                     + CAST(@cnt_rat  AS NVARCHAR(20));
    PRINT N'   + Notifications merchant1: '     + CAST(@cnt_noti AS NVARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    PRINT N'❌ ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO


/* =========================================================
   CLICKEAT — SEED THÁNG 2/2026 cho merchant1
   Timeline thực tế (ngày tính từ 2026-03-03):
     01/02 → 14/02 : Trước Tết  — hoạt động bình thường/bận
     15/02 → 22/02 : NGHỈ TẾT  — không có đơn nào
     23/02 → 28/02 : Sau Tết    — mở cửa lại, ít đơn, dần phục hồi

   Khoảng cách ngày tính từ SYSUTCDATETIME() (= 2026-03-03):
     01/02 = -30 ngày
     14/02 = -17 ngày  (ngày cuối trước nghỉ)
     15/02 = -16 ngày  (bắt đầu nghỉ)
     22/02 = -9  ngày  (ngày cuối nghỉ)
     23/02 = -8  ngày  (mở cửa lại)
     28/02 = -3  ngày
   ========================================================= */
SET NOCOUNT ON;
USE ClickEat;
GO

BEGIN TRY
    BEGIN TRAN;

    /* ── User IDs ───────────────────────────────────── */
    DECLARE @m1    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000002');
    DECLARE @c1    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000012');
    DECLARE @c2    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000013');
    DECLARE @c3    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000014');
    DECLARE @c4    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000015');
    DECLARE @c5    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000016');
    DECLARE @s1    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000007');
    DECLARE @s2    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000008');
    DECLARE @s3    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000009');
    DECLARE @admin BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000001');

    /* ── Food item IDs ──────────────────────────────── */
    DECLARE @fi_ga1   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Gà rán giòn');
    DECLARE @fi_ga2   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Gà cay');
    DECLARE @fi_bz    BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Burger Zinger');
    DECLARE @fi_bpm   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Burger Phô Mai');
    DECLARE @fi_bca   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Burger Cá Giòn');
    DECLARE @fi_ks    BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Khoai Tây Chiên Nhỏ');
    DECLARE @fi_kl    BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Khoai Tây Chiên Lớn');
    DECLARE @fi_pep   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Pepsi');
    DECLARE @fi_tra   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Trà Chanh Đào');
    DECLARE @fi_cb1   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Combo 1 Người');
    DECLARE @fi_cb2   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Combo 2 Người');
    DECLARE @fi_cbf   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Combo Gia Đình');
    DECLARE @fi_sal   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m1 AND name=N'Salad Kem');

    /* ── Voucher Tết ─────────────────────────────────── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Vouchers WHERE merchant_user_id=@m1 AND code=N'TET2026')
    INSERT INTO dbo.Vouchers
    (merchant_user_id,code,title,description,discount_type,discount_value,max_discount_amount,
     min_order_amount,start_at,end_at,max_uses_total,max_uses_per_user,is_published,status)
    VALUES
    (@m1,N'TET2026', N'Ưu đãi Tết Bính Ngọ',
     N'Giảm 30k cho đơn từ 150k – áp dụng từ 23/2 sau khi mở cửa lại',
     N'FIXED', 30000, NULL, 150000,
     '2026-02-23 00:00:00', '2026-03-10 23:59:59',
     300, 2, 1, N'ACTIVE'),
    (@m1,N'CHUCMUNG', N'Chúc mừng năm mới -15%',
     N'Giảm 15% tối đa 35k cho đơn từ 100k – áp dụng 1–14/2 trước Tết',
     N'PERCENT', 15, 35000, 100000,
     '2026-02-01 00:00:00', '2026-02-14 23:59:59',
     500, 3, 1, N'INACTIVE'); -- hết hạn

    /* =================================================
       PHẦN 1 — TRƯỚC TẾT: 01/02 → 14/02
       Bận rộn, đơn nhiều & giá trị cao (người mua sắm,
       đặt đồ ăn dịp Tết về sum họp)
       ================================================= */
    INSERT INTO dbo.Orders
    (order_code,customer_user_id,guest_id,merchant_user_id,shipper_user_id,
     receiver_name,receiver_phone,delivery_address_line,
     province_code,province_name,district_code,district_name,ward_code,ward_name,
     latitude,longitude,delivery_note,payment_method,payment_status,order_status,expires_at,
     subtotal_amount,delivery_fee,discount_amount,total_amount,
     created_at,accepted_at,ready_at,picked_up_at,delivered_at,cancelled_at)
    VALUES
    /* --- 01/02 (ngày -30) --- */
    (N'T2-0201-001',@c1,NULL,@m1,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     N'Đặt trước, giao đúng giờ',N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,35000,235000,
     '2026-02-01 09:00:00','2026-02-01 09:10:00','2026-02-01 09:35:00','2026-02-01 09:45:00','2026-02-01 10:15:00',NULL),

    (N'T2-0201-002',@c2,NULL,@m1,@s2,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     145000,15000,20000,140000,
     '2026-02-01 11:30:00','2026-02-01 11:40:00','2026-02-01 12:05:00','2026-02-01 12:15:00','2026-02-01 12:50:00',NULL),

    (N'T2-0201-003',@c3,NULL,@m1,@s3,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     '2026-02-01 18:00:00','2026-02-01 18:08:00','2026-02-01 18:30:00','2026-02-01 18:40:00','2026-02-01 19:10:00',NULL),

    /* --- 03/02 (ngày -28) --- */
    (N'T2-0203-001',@c4,NULL,@m1,@s1,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,0,270000,
     '2026-02-03 10:00:00','2026-02-03 10:12:00','2026-02-03 10:40:00','2026-02-03 10:50:00','2026-02-03 11:30:00',NULL),

    (N'T2-0203-002',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     195000,15000,0,210000,
     '2026-02-03 12:30:00','2026-02-03 12:42:00','2026-02-03 13:05:00','2026-02-03 13:15:00','2026-02-03 13:50:00',NULL),

    (N'T2-0203-003',@c1,NULL,@m1,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     65000,15000,0,80000,
     '2026-02-03 19:00:00',NULL,NULL,NULL,NULL,'2026-02-03 19:05:00'),

    /* --- 05/02 (ngày -26) --- */
    (N'T2-0205-001',@c2,NULL,@m1,@s1,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,30000,240000,
     '2026-02-05 08:30:00','2026-02-05 08:42:00','2026-02-05 09:10:00','2026-02-05 09:20:00','2026-02-05 09:55:00',NULL),

    (N'T2-0205-002',@c3,NULL,@m1,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     N'Gọi trước khi tới',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     '2026-02-05 12:00:00','2026-02-05 12:10:00','2026-02-05 12:35:00','2026-02-05 12:45:00','2026-02-05 13:20:00',NULL),

    (N'T2-0205-003',@c4,NULL,@m1,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     '2026-02-05 17:00:00','2026-02-05 17:08:00','2026-02-05 17:30:00','2026-02-05 17:40:00','2026-02-05 18:15:00',NULL),

    /* --- 07/02 (ngày -24) --- */
    (N'T2-0207-001',@c5,NULL,@m1,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,0,270000,
     '2026-02-07 09:00:00','2026-02-07 09:15:00','2026-02-07 09:40:00','2026-02-07 09:50:00','2026-02-07 10:30:00',NULL),

    (N'T2-0207-002',@c1,NULL,@m1,@s2,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     N'Đơn họp gia đình',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     500000,20000,35000,485000,
     '2026-02-07 11:00:00','2026-02-07 11:12:00','2026-02-07 11:45:00','2026-02-07 11:55:00','2026-02-07 12:40:00',NULL),

    (N'T2-0207-003',@c2,NULL,@m1,@s3,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     '2026-02-07 17:30:00','2026-02-07 17:40:00','2026-02-07 18:05:00','2026-02-07 18:15:00','2026-02-07 18:50:00',NULL),

    /* --- 09/02 (ngày -22) — đông nhất trước Tết --- */
    (N'T2-0209-001',@c3,NULL,@m1,@s1,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     N'Đặt gấp, giao sớm',N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,35000,235000,
     '2026-02-09 10:30:00','2026-02-09 10:38:00','2026-02-09 11:00:00','2026-02-09 11:10:00','2026-02-09 11:45:00',NULL),

    (N'T2-0209-002',@c4,NULL,@m1,@s2,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     500000,20000,35000,485000,
     '2026-02-09 12:00:00','2026-02-09 12:10:00','2026-02-09 12:40:00','2026-02-09 12:50:00','2026-02-09 13:35:00',NULL),

    (N'T2-0209-003',@c5,NULL,@m1,@s3,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     195000,15000,0,210000,
     '2026-02-09 17:00:00','2026-02-09 17:12:00','2026-02-09 17:38:00','2026-02-09 17:48:00','2026-02-09 18:25:00',NULL),

    (N'T2-0209-004',@c1,NULL,@m1,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     '2026-02-09 19:30:00','2026-02-09 19:40:00','2026-02-09 20:00:00','2026-02-09 20:10:00','2026-02-09 20:45:00',NULL),

    /* --- 11/02 (ngày -20) --- */
    (N'T2-0211-001',@c2,NULL,@m1,@s2,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     N'Đặt gấp cho tiệc',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     500000,20000,35000,485000,
     '2026-02-11 10:00:00','2026-02-11 10:08:00','2026-02-11 10:35:00','2026-02-11 10:45:00','2026-02-11 11:20:00',NULL),

    (N'T2-0211-002',@c3,NULL,@m1,@s3,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,0,270000,
     '2026-02-11 12:30:00','2026-02-11 12:40:00','2026-02-11 13:05:00','2026-02-11 13:15:00','2026-02-11 13:55:00',NULL),

    (N'T2-0211-003',@c4,NULL,@m1,@s1,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     145000,15000,0,160000,
     '2026-02-11 18:00:00',NULL,NULL,NULL,NULL,'2026-02-11 18:05:00'),

    /* --- 12/02 (ngày -19) --- */
    (N'T2-0212-001',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     N'Đặt tiệc tất niên sớm',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     500000,20000,35000,485000,
     '2026-02-12 11:00:00','2026-02-12 11:10:00','2026-02-12 11:40:00','2026-02-12 11:50:00','2026-02-12 12:30:00',NULL),

    (N'T2-0212-002',@c1,NULL,@m1,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     195000,15000,0,210000,
     '2026-02-12 18:00:00','2026-02-12 18:10:00','2026-02-12 18:35:00','2026-02-12 18:45:00','2026-02-12 19:20:00',NULL),

    /* --- 13/02 (ngày -18) --- */
    (N'T2-0213-001',@c2,NULL,@m1,@s1,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     N'Giao tất niên',N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,35000,235000,
     '2026-02-13 09:00:00','2026-02-13 09:10:00','2026-02-13 09:40:00','2026-02-13 09:50:00','2026-02-13 10:30:00',NULL),

    (N'T2-0213-002',@c3,NULL,@m1,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     500000,20000,0,520000,
     '2026-02-13 12:00:00','2026-02-13 12:12:00','2026-02-13 12:45:00','2026-02-13 12:55:00','2026-02-13 13:40:00',NULL),

    (N'T2-0213-003',@c4,NULL,@m1,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     '2026-02-13 17:30:00','2026-02-13 17:40:00','2026-02-13 18:05:00','2026-02-13 18:15:00','2026-02-13 18:50:00',NULL),

    (N'T2-0213-004',@c5,NULL,@m1,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     N'Đơn cuối trước nghỉ Tết',N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     '2026-02-13 20:00:00','2026-02-13 20:10:00','2026-02-13 20:30:00','2026-02-13 20:40:00','2026-02-13 21:10:00',NULL),

    /* --- 14/02 (ngày -17) — ngày cuối cùng trước nghỉ --- */
    (N'T2-0214-001',@c1,NULL,@m1,@s2,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     N'Bữa tất niên cuối cùng!',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     500000,20000,35000,485000,
     '2026-02-14 10:00:00','2026-02-14 10:10:00','2026-02-14 10:45:00','2026-02-14 10:55:00','2026-02-14 11:40:00',NULL),

    (N'T2-0214-002',@c2,NULL,@m1,@s3,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,30000,240000,
     '2026-02-14 11:30:00','2026-02-14 11:42:00','2026-02-14 12:08:00','2026-02-14 12:18:00','2026-02-14 13:00:00',NULL),

    (N'T2-0214-003',@c3,NULL,@m1,@s1,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     N'Đơn cuối ngày 14/2',N'COD',N'PAID',N'DELIVERED',NULL,
     195000,15000,0,210000,
     '2026-02-14 17:00:00','2026-02-14 17:10:00','2026-02-14 17:35:00','2026-02-14 17:45:00','2026-02-14 18:25:00',NULL),

    /* -------------------------------------------------------------------------
       NGHỈ TẾT 15/02 → 22/02 — KHÔNG CÓ ĐƠN HÀNG NÀO
       -------------------------------------------------------------------------
       (khoảng trống này thể hiện cửa hàng đóng cửa nghỉ Tết)
       Dữ liệu timeline sẽ cho thấy không có doanh thu 8 ngày liên tiếp.
       ------------------------------------------------------------------------- */

    /* =================================================
       PHẦN 2 — SAU TẾT MỞ CỬA: 23/02 → 28/02
       Ít đơn hơn, dần phục hồi, khách quay lại
       ================================================= */

    /* --- 23/02 (ngày -8) — ngày đầu mở cửa lại --- */
    (N'T2-0223-001',@c4,NULL,@m1,@s2,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     N'Chờ lâu xíu nha shop mới mở lại',N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     '2026-02-23 10:30:00','2026-02-23 10:45:00','2026-02-23 11:15:00','2026-02-23 11:25:00','2026-02-23 12:10:00',NULL),

    (N'T2-0223-002',@c5,NULL,@m1,@s3,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,30000,130000,
     '2026-02-23 13:00:00','2026-02-23 13:15:00','2026-02-23 13:45:00','2026-02-23 13:55:00','2026-02-23 14:35:00',NULL),

    /* --- 24/02 (ngày -7) --- */
    (N'T2-0224-001',@c1,NULL,@m1,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     250000,20000,30000,240000,
     '2026-02-24 11:00:00','2026-02-24 11:12:00','2026-02-24 11:40:00','2026-02-24 11:50:00','2026-02-24 12:35:00',NULL),

    (N'T2-0224-002',@c2,NULL,@m1,@s2,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     '2026-02-24 17:30:00','2026-02-24 17:42:00','2026-02-24 18:05:00','2026-02-24 18:15:00','2026-02-24 18:55:00',NULL),

    /* --- 25/02 (ngày -6) --- */
    (N'T2-0225-001',@c3,NULL,@m1,@s3,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     '2026-02-25 09:30:00','2026-02-25 09:42:00','2026-02-25 10:08:00','2026-02-25 10:18:00','2026-02-25 10:55:00',NULL),

    (N'T2-0225-002',@c4,NULL,@m1,@s1,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     N'Dùng voucher TET2026',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     195000,15000,30000,180000,
     '2026-02-25 12:00:00','2026-02-25 12:10:00','2026-02-25 12:38:00','2026-02-25 12:48:00','2026-02-25 13:30:00',NULL),

    (N'T2-0225-003',@c5,NULL,@m1,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     65000,15000,0,80000,
     '2026-02-25 19:00:00',NULL,NULL,NULL,NULL,'2026-02-25 19:08:00'),

    /* --- 26/02 (ngày -5) --- */
    (N'T2-0226-001',@c1,NULL,@m1,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,30000,240000,
     '2026-02-26 10:00:00','2026-02-26 10:12:00','2026-02-26 10:40:00','2026-02-26 10:50:00','2026-02-26 11:35:00',NULL),

    (N'T2-0226-002',@c2,NULL,@m1,@s1,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     '2026-02-26 13:00:00','2026-02-26 13:10:00','2026-02-26 13:35:00','2026-02-26 13:45:00','2026-02-26 14:20:00',NULL),

    /* --- 27/02 (ngày -4) --- */
    (N'T2-0227-001',@c3,NULL,@m1,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     195000,15000,0,210000,
     '2026-02-27 09:00:00','2026-02-27 09:12:00','2026-02-27 09:38:00','2026-02-27 09:48:00','2026-02-27 10:25:00',NULL),

    (N'T2-0227-002',@c4,NULL,@m1,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     N'Dùng voucher TET2026',N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,30000,240000,
     '2026-02-27 11:30:00','2026-02-27 11:42:00','2026-02-27 12:10:00','2026-02-27 12:20:00','2026-02-27 13:05:00',NULL),

    (N'T2-0227-003',@c5,NULL,@m1,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     75000,15000,0,90000,
     '2026-02-27 17:00:00','2026-02-27 17:10:00','2026-02-27 17:32:00','2026-02-27 17:42:00','2026-02-27 18:15:00',NULL),

    /* --- 28/02 (ngày -3) --- */
    (N'T2-0228-001',@c1,NULL,@m1,@s2,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     250000,20000,0,270000,
     '2026-02-28 10:00:00','2026-02-28 10:10:00','2026-02-28 10:40:00','2026-02-28 10:50:00','2026-02-28 11:35:00',NULL),

    (N'T2-0228-002',@c2,NULL,@m1,@s3,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     500000,20000,30000,490000,
     '2026-02-28 12:00:00','2026-02-28 12:12:00','2026-02-28 12:45:00','2026-02-28 12:55:00','2026-02-28 13:45:00',NULL),

    (N'T2-0228-003',@c3,NULL,@m1,@s1,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     145000,15000,0,160000,
     '2026-02-28 17:30:00','2026-02-28 17:40:00','2026-02-28 18:05:00','2026-02-28 18:15:00','2026-02-28 18:55:00',NULL);

    /* ── OrderItems ─────────────────────────────────── */
    INSERT INTO dbo.OrderItems(order_id,food_item_id,item_name_snapshot,unit_price_snapshot,quantity,note)
    -- Trước Tết - đơn gia đình lớn
    SELECT o.id,@fi_cbf,N'Combo Gia Đình',250000,1,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0201-001',N'T2-0203-001',N'T2-0205-001',N'T2-0207-001',
        N'T2-0209-001',N'T2-0211-001',N'T2-0212-001',N'T2-0213-002',
        N'T2-0214-001',N'T2-0226-001',N'T2-0228-002') UNION ALL
    -- Combo 2 người
    SELECT o.id,@fi_cb2,N'Combo 2 Người',145000,1,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0201-002',N'T2-0205-003',N'T2-0209-003',N'T2-0211-002',
        N'T2-0213-003',N'T2-0224-001',N'T2-0225-001',N'T2-0227-001',
        N'T2-0228-001') UNION ALL
    -- Combo 1 người
    SELECT o.id,@fi_cb1,N'Combo 1 Người',75000,1,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0201-003',N'T2-0203-003',N'T2-0207-003',N'T2-0209-004',
        N'T2-0213-004',N'T2-0223-001',N'T2-0224-002',N'T2-0227-003',
        N'T2-0228-003') UNION ALL
    -- Burger Zinger
    SELECT o.id,@fi_bz,N'Burger Zinger',65000,1,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0203-003',N'T2-0211-003',N'T2-0225-003') UNION ALL
    -- Đơn huỷ
    SELECT o.id,@fi_cb1,N'Combo 1 Người',75000,1,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0203-003') UNION ALL
    -- Đơn lớn 500k (2x Combo Gia Đình)
    SELECT o.id,@fi_cbf,N'Combo Gia Đình',250000,2,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0207-002',N'T2-0209-002',N'T2-0212-001',N'T2-0214-002') UNION ALL
    -- Combo 2 + Khoai + nước cho đơn vừa
    SELECT o.id,@fi_cb2,N'Combo 2 Người',145000,1,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0203-002',N'T2-0225-002',N'T2-0226-002',N'T2-0227-002') UNION ALL
    SELECT o.id,@fi_kl,N'Khoai Tây Chiên Lớn',35000,1,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0205-002',N'T2-0213-001',N'T2-0223-002',N'T2-0227-002') UNION ALL
    SELECT o.id,@fi_pep,N'Pepsi',18000,2,NULL FROM dbo.Orders o WHERE o.order_code IN (
        N'T2-0205-002',N'T2-0213-001');

    /* ── Status history ──────────────────────────────── */
    -- Đơn DELIVERED
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,
           DATEADD(MINUTE,-5,o.accepted_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m1,NULL,o.accepted_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m1,NULL,
           DATEADD(MINUTE,3,o.accepted_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PREPARING',N'READY_FOR_PICKUP',N'MERCHANT',@m1,NULL,o.ready_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'READY_FOR_PICKUP',N'PICKED_UP',N'SHIPPER',o.shipper_user_id,NULL,o.picked_up_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PICKED_UP',N'DELIVERED',N'SHIPPER',o.shipper_user_id,NULL,o.delivered_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'DELIVERED';

    -- Đơn CANCELLED
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,
           DATEADD(MINUTE,-2,o.cancelled_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'CANCELLED'
    UNION ALL
    SELECT o.id,N'CREATED',N'CANCELLED',N'CUSTOMER',o.customer_user_id,N'Khách huỷ đơn',
           o.cancelled_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%' AND o.order_status=N'CANCELLED';

    /* ── PaymentTransactions ─────────────────────────── */
    INSERT INTO dbo.PaymentTransactions(order_id,provider,amount,status,created_at)
    SELECT o.id, o.payment_method, o.total_amount,
           CASE WHEN o.order_status=N'DELIVERED' THEN N'SUCCESS'
                WHEN o.order_status=N'CANCELLED' THEN N'FAILED'
                ELSE N'INITIATED' END,
           o.created_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'T2-%';

    /* ── Ratings ─────────────────────────────────────── */
    INSERT INTO dbo.Ratings(order_id,rater_customer_id,rater_guest_id,target_type,target_user_id,stars,comment,created_at)
    SELECT o.id, o.customer_user_id, NULL, N'MERCHANT', @m1,
           CASE (o.id % 5)
               WHEN 0 THEN 5 WHEN 1 THEN 5 WHEN 2 THEN 4
               WHEN 3 THEN 4 ELSE 3 END,
           CASE (o.id % 9)
               WHEN 0 THEN N'Đồ ăn tươi ngon, giao đúng giờ!'
               WHEN 1 THEN N'Tất niên ngon tuyệt, cả nhà khen!'
               WHEN 2 THEN N'Gà giòn được, giao nhanh'
               WHEN 3 THEN N'Đóng gói cẩn thận, sẽ đặt lại'
               WHEN 4 THEN N'Combo gia đình xứng đáng đồng tiền, rất ngon!'
               WHEN 5 THEN N'Mở cửa lại sau Tết rất đúng giờ, hài lòng'
               WHEN 6 THEN N'Sau Tết về đặt ngay, đỡ phải nấu :D'
               WHEN 7 THEN N'Ổn, vẫn đảm bảo chất lượng sau kỳ nghỉ'
               ELSE      N'Giao hơi lâu nhưng đồ ăn ngon bù lại' END,
           DATEADD(MINUTE,30,o.delivered_at)
    FROM dbo.Orders o
    WHERE o.order_code LIKE N'T2-%'
      AND o.order_status = N'DELIVERED'
      AND NOT EXISTS (SELECT 1 FROM dbo.Ratings r WHERE r.order_id=o.id AND r.target_type=N'MERCHANT');

    /* ── Notifications ────────────────────────────────── */
    INSERT INTO dbo.Notifications(user_id,guest_id,type,content,is_read,created_at)
    VALUES
    -- Trước Tết
    (@m1,NULL,N'SYSTEM',
     N'Nhắc nhở: Cửa hàng của bạn đã đặt lịch NGHỈ TẾT từ 15/02 đến 22/02/2026. Khách hàng sẽ không thể đặt đơn.',
     1,'2026-02-13 08:00:00'),
    (@m1,NULL,N'SYSTEM',
     N'Hôm nay (14/02) là ngày cuối trước nghỉ Tết. Chúc mừng năm mới Bính Ngọ!',
     1,'2026-02-14 07:00:00'),
    (@m1,NULL,N'ORDER_NEW',
     N'Đơn T2-0214-001 (485,000đ) — đơn tất niên cuối cùng trước nghỉ Tết!',
     1,'2026-02-14 10:02:00'),
    -- Trong nghỉ Tết
    (@m1,NULL,N'SYSTEM',
     N'Cửa hàng đang tạm nghỉ Tết đến 22/02/2026. Chúc Tết an lành!',
     1,'2026-02-15 00:01:00'),
    -- Mở cửa lại
    (@m1,NULL,N'SYSTEM',
     N'Cửa hàng của bạn đã mở lại hôm nay (23/02). Chúc kinh doanh thuận lợi sau Tết!',
     0,'2026-02-23 09:00:00'),
    (@m1,NULL,N'ORDER_NEW',
     N'Đơn T2-0223-001 (90,000đ) — đơn đầu tiên sau nghỉ Tết!',
     0,'2026-02-23 10:32:00'),
    (@m1,NULL,N'REVIEW',
     N'Khách hàng đánh giá 5⭐: "Mở cửa lại sau Tết rất đúng giờ, hài lòng"',
     0,'2026-02-23 13:20:00'),
    (@m1,NULL,N'SYSTEM',
     N'Voucher TET2026 của bạn đang được khách hàng sử dụng nhiều sau kỳ nghỉ.',
     0,'2026-02-25 14:00:00'),
    (@m1,NULL,N'SYSTEM',
     N'Doanh thu tuần sau Tết (23-28/02) đạt 2.9 triệu đồng. Đang phục hồi tốt!',
     0,'2026-02-28 23:59:00');

    COMMIT TRAN;

    /* ── Tóm tắt ──────────────────────────────────────── */
    DECLARE @t2_total   INT;
    DECLARE @t2_dlv     INT;
    DECLARE @t2_can     INT;
    DECLARE @t2_rev     DECIMAL(18,2);
    DECLARE @t2_pretết  INT;
    DECLARE @t2_posttết INT;

    SELECT @t2_total  = COUNT(*) FROM dbo.Orders WHERE order_code LIKE N'T2-%';
    SELECT @t2_dlv    = COUNT(*) FROM dbo.Orders WHERE order_code LIKE N'T2-%' AND order_status=N'DELIVERED';
    SELECT @t2_can    = COUNT(*) FROM dbo.Orders WHERE order_code LIKE N'T2-%' AND order_status=N'CANCELLED';
    SELECT @t2_rev    = ISNULL(SUM(total_amount),0) FROM dbo.Orders WHERE order_code LIKE N'T2-%' AND order_status=N'DELIVERED';
    SELECT @t2_pretết = COUNT(*) FROM dbo.Orders WHERE order_code LIKE N'T2-%' AND created_at < '2026-02-15';
    SELECT @t2_posttết= COUNT(*) FROM dbo.Orders WHERE order_code LIKE N'T2-%' AND created_at >= '2026-02-23';

    PRINT N'✅ SEED THÁNG 2 completed!';
    PRINT N'   Tổng đơn tháng 2: '                    + CAST(@t2_total   AS NVARCHAR(10));
    PRINT N'   DELIVERED: '                            + CAST(@t2_dlv    AS NVARCHAR(10));
    PRINT N'   CANCELLED: '                            + CAST(@t2_can    AS NVARCHAR(10));
    PRINT N'   Doanh thu (DELIVERED): '               + CAST(@t2_rev    AS NVARCHAR(20)) + N' đ';
    PRINT N'   Đơn trước Tết (01-14/02): '            + CAST(@t2_pretết AS NVARCHAR(10));
    PRINT N'   Đơn sau Tết mở cửa (23-28/02): '       + CAST(@t2_posttết AS NVARCHAR(10));
    PRINT N'   Nghỉ Tết 15/02 → 22/02: 0 đơn (khoảng trống)';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    PRINT N'❌ ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO


/* =========================================================
   SECTION 20 — MERCHANT DATA ENRICHMENT
   Làm giàu dữ liệu cho merchant 2-5:
     - Merchant2 (Lollibee Q3, APPROVED): 4 categories, 12 food items,
       2 vouchers, 16 orders (15 delivered + 1 cancelled), ratings, notifications
     - Merchant3 (Lollibee BT, APPROVED): 3 categories, 8 food items,
       1 voucher, 12 orders (10 delivered + 1 cancelled + 1 preparing), ratings, notifications
     - Merchant4 (Lollibee TD, PENDING): 3 categories, 8 food items
     - Merchant5 (Lollibee DN, PENDING): 3 categories, 6 food items
   ========================================================= */
SET NOCOUNT ON;
USE ClickEat;
GO

BEGIN TRY
    BEGIN TRAN;

    /* ── Lấy lại user IDs ──────────────────────────── */
    DECLARE @m2    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000003');
    DECLARE @m3    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000004');
    DECLARE @m4    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000005');
    DECLARE @m5    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000006');
    DECLARE @c1    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000012');
    DECLARE @c2    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000013');
    DECLARE @c3    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000014');
    DECLARE @c4    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000015');
    DECLARE @c5    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000016');
    DECLARE @s1    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000007');
    DECLARE @s2    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000008');
    DECLARE @s3    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000009');
    DECLARE @s4    BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000010');
    DECLARE @admin BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000001');


    /* ================================================================
       MERCHANT 2 — Lollibee Q3  (250 CMT8, Quận 3, APPROVED)
       Định hướng: Combo + Gà Rán, thêm Burger, Đồ Uống
       ================================================================ */

    /* ── Categories cho merchant2 ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Gà Rán')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m2,N'Gà Rán',1,2);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Khoai & Món Phụ')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m2,N'Khoai & Món Phụ',1,3);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Đồ Uống')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m2,N'Đồ Uống',1,4);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Burger')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m2,N'Burger',1,5);

    DECLARE @m2_cat_combo  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Combo');
    DECLARE @m2_cat_ga     BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Gà Rán');
    DECLARE @m2_cat_khoai  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Khoai & Món Phụ');
    DECLARE @m2_cat_drink  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Đồ Uống');
    DECLARE @m2_cat_burger BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m2 AND name=N'Burger');

    /* ── Food items cho merchant2 (12 món mới) ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Gà Rán Original')
    INSERT INTO dbo.FoodItems(merchant_user_id,category_id,name,description,price,is_available,is_fried,calories,protein_g,carbs_g,fat_g)
    VALUES
    (@m2,@m2_cat_ga,    N'Gà Rán Original',    N'Gà rán vàng giòn công thức truyền thống',          45000,1,1,520,28,35,22),
    (@m2,@m2_cat_ga,    N'Gà Cay Special',      N'Gà rán cay đậm đà gia vị riêng',                   52000,1,1,560,30,37,24),
    (@m2,@m2_cat_ga,    N'Gà Phủ Phô Mai',      N'Gà rán phủ phô mai Cheddar nóng chảy',             58000,1,1,610,34,38,28),
    (@m2,@m2_cat_khoai, N'Khoai Tây Chiên',     N'Khoai tây vàng giòn cỡ vừa',                       22000,1,1,340,4,43,15),
    (@m2,@m2_cat_khoai, N'Bắp Nướng Bơ',        N'Bắp nướng bơ tỏi thơm, ăn kèm tuyệt vời',         20000,1,0,190,5,38,5),
    (@m2,@m2_cat_khoai, N'Súp Ngô Kem',         N'Súp ngô tươi ngọt nhẹ, kết hợp kem tươi',          18000,1,0,180,6,28,6),
    (@m2,@m2_cat_drink, N'Pepsi Lon',            N'Pepsi lạnh 330ml',                                  18000,1,0,147,0,38,0),
    (@m2,@m2_cat_drink, N'7Up Lon',              N'7Up chanh mát lạnh 330ml',                          18000,1,0,130,0,33,0),
    (@m2,@m2_cat_drink, N'Nước Cam Tươi',        N'Nước cam vắt tươi, không thêm đường',               25000,1,0,120,2,28,0),
    (@m2,@m2_cat_drink, N'Trà Đào Đá',           N'Trà đào mát lạnh, thêm đào tươi',                  22000,1,0,110,0,27,0),
    (@m2,@m2_cat_burger,N'Burger Gà Nướng',      N'Burger gà nướng sốt BBQ khói đặc biệt',            65000,1,0,620,32,68,22),
    (@m2,@m2_cat_burger,N'Burger Double Stack',  N'Burger 2 lớp gà giòn, phô mai, rau tươi',          85000,1,1,850,45,80,38);

    /* ── Food item IDs merchant2 ── */
    DECLARE @m2_cb1   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Combo 1');
    DECLARE @m2_cb2   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Combo 2');
    DECLARE @m2_ga1   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Gà Rán Original');
    DECLARE @m2_ga2   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Gà Cay Special');
    DECLARE @m2_ga3   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Gà Phủ Phô Mai');
    DECLARE @m2_kh    BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Khoai Tây Chiên');
    DECLARE @m2_bap   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Bắp Nướng Bơ');
    DECLARE @m2_pep   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Pepsi Lon');
    DECLARE @m2_cam   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Nước Cam Tươi');
    DECLARE @m2_tra   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Trà Đào Đá');
    DECLARE @m2_bur1  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Burger Gà Nướng');
    DECLARE @m2_bur2  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m2 AND name=N'Burger Double Stack');

    /* ── Vouchers cho merchant2 ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Vouchers WHERE merchant_user_id=@m2 AND code=N'Q3SALE')
    INSERT INTO dbo.Vouchers(merchant_user_id,code,title,description,discount_type,discount_value,
                             max_discount_amount,min_order_amount,start_at,end_at,
                             max_uses_total,max_uses_per_user,is_published,status)
    VALUES
    (@m2,N'Q3SALE',  N'Khuyến mãi Quận 3',  N'Giảm 15k cho đơn từ 70k',              N'FIXED',  15000,NULL, 70000,
     DATEADD(DAY,-10,SYSUTCDATETIME()),DATEADD(DAY,20,SYSUTCDATETIME()),300,2,1,N'ACTIVE'),
    (@m2,N'COMBO20', N'Combo giảm 20%',      N'Giảm 20% tối đa 25k, đơn từ 80k',     N'PERCENT',20,   25000,80000,
     DATEADD(DAY, -3,SYSUTCDATETIME()),DATEADD(DAY,14,SYSUTCDATETIME()),150,1,1,N'ACTIVE'),
    (@m2,N'WELCOME', N'Chào khách mới -10k', N'Giảm 10k cho lần đặt đầu tiên từ 50k',N'FIXED',  10000,NULL, 50000,
     DATEADD(DAY,-30,SYSUTCDATETIME()),DATEADD(DAY,60,SYSUTCDATETIME()),500,1,1,N'ACTIVE');

    /* ── 16 đơn hàng cho merchant2 (15 DELIVERED, 1 CANCELLED) ── */
    /*
       Subtotal check:
       M2-D0-001 : BurgerGàNướng(65k)               = 65k  + fee15 - disc0 = 80k
       M2-D1-001 : Combo1(79k)                       = 79k  + fee15 - disc0 = 94k
       M2-D1-002 : Combo2(89k)+GàCay(52k)            = 141k + fee15 - disc15(Q3SALE) = 141k
       M2-D2-001 : Combo2(89k)                       = 89k  + fee15 - disc0  = 104k
       M2-D3-001 : Combo1(79k)                       = 79k  + fee15 - disc0  = 94k
       M2-D3-002 : BurgerDouble(85k)+GàRán(45k)+Pepsi(18k) = 148k + fee15 - disc25(COMBO20 20%cap25) = 138k
       M2-D5-001 : Combo2(89k)                       = 89k  + fee15 - disc0  = 104k
       M2-D6-001 : Combo1(79k) CANCELLED             = 79k  + fee15 - disc0  = 94k
       M2-D7-001 : Combo1(79k)+Khoai(22k)            = 101k + fee15 - disc0  = 116k
       M2-D9-001 : Combo2(89k)                       = 89k  + fee15 - disc0  = 104k
       M2-D11-001: Combo1(79k)                       = 79k  + fee15 - disc0  = 94k
       M2-D13-001: Combo1(79k)+GàPhủ(58k)            = 137k + fee15 - disc15(Q3SALE) = 137k
       M2-D15-001: Combo2(89k)                       = 89k  + fee15 - disc0  = 104k
       M2-D17-001: Combo1(79k)                       = 79k  + fee15 - disc0  = 94k
       M2-D20-001: Combo1(79k)+GàCay(52k)            = 131k + fee15 - disc0  = 146k
       M2-D22-001: Combo2(89k)                       = 89k  + fee15 - disc0  = 104k
    */
    INSERT INTO dbo.Orders
    (order_code,customer_user_id,guest_id,merchant_user_id,shipper_user_id,
     receiver_name,receiver_phone,delivery_address_line,
     province_code,province_name,district_code,district_name,ward_code,ward_name,
     latitude,longitude,delivery_note,payment_method,payment_status,order_status,expires_at,
     subtotal_amount,delivery_fee,discount_amount,total_amount,
     accepted_at,ready_at,picked_up_at,delivered_at,cancelled_at)
    VALUES
    /* Đơn đang xử lý hôm nay */
    (N'M2-D0-001',@c3,NULL,@m2,@s4,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     N'Để lễ tân',N'COD',N'UNPAID',N'PREPARING',NULL,
     65000,15000,0,80000,
     DATEADD(MINUTE,-20,SYSUTCDATETIME()),NULL,NULL,NULL,NULL),

    /* Hôm qua (D1) */
    (N'M2-D1-001',@c1,NULL,@m2,@s1,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     79000,15000,0,94000,
     DATEADD(DAY,-1,DATEADD(HOUR,2,SYSUTCDATETIME())),
     DATEADD(DAY,-1,DATEADD(MINUTE,-100,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-1,DATEADD(MINUTE,-88,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-1,DATEADD(MINUTE,-60,DATEADD(HOUR,3,SYSUTCDATETIME()))),NULL),

    (N'M2-D1-002',@c4,NULL,@m2,@s2,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     141000,15000,15000,141000,
     DATEADD(DAY,-1,DATEADD(HOUR,6,SYSUTCDATETIME())),
     DATEADD(DAY,-1,DATEADD(MINUTE,-25,DATEADD(HOUR,7,SYSUTCDATETIME()))),
     DATEADD(DAY,-1,DATEADD(MINUTE,-13,DATEADD(HOUR,7,SYSUTCDATETIME()))),
     DATEADD(DAY,-1,DATEADD(MINUTE,20,DATEADD(HOUR,7,SYSUTCDATETIME()))),NULL),

    /* 2 ngày trước (D2) */
    (N'M2-D2-001',@c5,NULL,@m2,@s3,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     89000,15000,0,104000,
     DATEADD(DAY,-2,DATEADD(HOUR,4,SYSUTCDATETIME())),
     DATEADD(DAY,-2,DATEADD(MINUTE,-20,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-2,DATEADD(MINUTE,-8,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-2,DATEADD(MINUTE,22,DATEADD(HOUR,5,SYSUTCDATETIME()))),NULL),

    /* 3 ngày trước (D3) — 2 đơn */
    (N'M2-D3-001',@c2,NULL,@m2,@s4,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     79000,15000,0,94000,
     DATEADD(DAY,-3,DATEADD(HOUR,2,SYSUTCDATETIME())),
     DATEADD(DAY,-3,DATEADD(MINUTE,-22,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-3,DATEADD(MINUTE,-10,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-3,DATEADD(MINUTE,18,DATEADD(HOUR,3,SYSUTCDATETIME()))),NULL),

    (N'M2-D3-002',@c3,NULL,@m2,@s1,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     N'Giao giờ trưa',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     148000,15000,25000,138000,
     DATEADD(DAY,-3,DATEADD(HOUR,10,SYSUTCDATETIME())),
     DATEADD(DAY,-3,DATEADD(MINUTE,-18,DATEADD(HOUR,11,SYSUTCDATETIME()))),
     DATEADD(DAY,-3,DATEADD(MINUTE,-5,DATEADD(HOUR,11,SYSUTCDATETIME()))),
     DATEADD(DAY,-3,DATEADD(MINUTE,28,DATEADD(HOUR,11,SYSUTCDATETIME()))),NULL),

    /* 5,7,9,11,13,15,17,20,22 ngày trước */
    (N'M2-D5-001',@c5,NULL,@m2,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     89000,15000,0,104000,
     DATEADD(DAY,-5,DATEADD(HOUR,3,SYSUTCDATETIME())),
     DATEADD(DAY,-5,DATEADD(MINUTE,-23,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-5,DATEADD(MINUTE,-11,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-5,DATEADD(MINUTE,20,DATEADD(HOUR,4,SYSUTCDATETIME()))),NULL),

    (N'M2-D6-001',@c1,NULL,@m2,NULL,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     79000,15000,0,94000,
     NULL,NULL,NULL,NULL,DATEADD(DAY,-6,DATEADD(HOUR,8,SYSUTCDATETIME()))),

    (N'M2-D7-001',@c4,NULL,@m2,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     101000,15000,0,116000,
     DATEADD(DAY,-7,DATEADD(HOUR,5,SYSUTCDATETIME())),
     DATEADD(DAY,-7,DATEADD(MINUTE,-22,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-7,DATEADD(MINUTE,-10,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-7,DATEADD(MINUTE,22,DATEADD(HOUR,6,SYSUTCDATETIME()))),NULL),

    (N'M2-D9-001',@c2,NULL,@m2,@s4,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     89000,15000,0,104000,
     DATEADD(DAY,-9,DATEADD(HOUR,4,SYSUTCDATETIME())),
     DATEADD(DAY,-9,DATEADD(MINUTE,-23,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-9,DATEADD(MINUTE,-11,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-9,DATEADD(MINUTE,20,DATEADD(HOUR,5,SYSUTCDATETIME()))),NULL),

    (N'M2-D11-001',@c5,NULL,@m2,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     79000,15000,0,94000,
     DATEADD(DAY,-11,DATEADD(HOUR,3,SYSUTCDATETIME())),
     DATEADD(DAY,-11,DATEADD(MINUTE,-22,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-11,DATEADD(MINUTE,-10,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-11,DATEADD(MINUTE,18,DATEADD(HOUR,4,SYSUTCDATETIME()))),NULL),

    (N'M2-D13-001',@c3,NULL,@m2,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     137000,15000,15000,137000,
     DATEADD(DAY,-13,DATEADD(HOUR,6,SYSUTCDATETIME())),
     DATEADD(DAY,-13,DATEADD(MINUTE,-25,DATEADD(HOUR,7,SYSUTCDATETIME()))),
     DATEADD(DAY,-13,DATEADD(MINUTE,-12,DATEADD(HOUR,7,SYSUTCDATETIME()))),
     DATEADD(DAY,-13,DATEADD(MINUTE,20,DATEADD(HOUR,7,SYSUTCDATETIME()))),NULL),

    (N'M2-D15-001',@c1,NULL,@m2,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     89000,15000,0,104000,
     DATEADD(DAY,-15,DATEADD(HOUR,2,SYSUTCDATETIME())),
     DATEADD(DAY,-15,DATEADD(MINUTE,-22,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-15,DATEADD(MINUTE,-10,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-15,DATEADD(MINUTE,20,DATEADD(HOUR,3,SYSUTCDATETIME()))),NULL),

    (N'M2-D17-001',@c4,NULL,@m2,@s4,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     79000,15000,0,94000,
     DATEADD(DAY,-17,DATEADD(HOUR,5,SYSUTCDATETIME())),
     DATEADD(DAY,-17,DATEADD(MINUTE,-21,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-17,DATEADD(MINUTE,-9,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-17,DATEADD(MINUTE,22,DATEADD(HOUR,6,SYSUTCDATETIME()))),NULL),

    (N'M2-D20-001',@c2,NULL,@m2,@s1,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     131000,15000,0,146000,
     DATEADD(DAY,-20,DATEADD(HOUR,4,SYSUTCDATETIME())),
     DATEADD(DAY,-20,DATEADD(MINUTE,-24,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-20,DATEADD(MINUTE,-12,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-20,DATEADD(MINUTE,20,DATEADD(HOUR,5,SYSUTCDATETIME()))),NULL),

    (N'M2-D22-001',@c5,NULL,@m2,@s2,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     89000,15000,0,104000,
     DATEADD(DAY,-22,DATEADD(HOUR,3,SYSUTCDATETIME())),
     DATEADD(DAY,-22,DATEADD(MINUTE,-23,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-22,DATEADD(MINUTE,-11,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-22,DATEADD(MINUTE,21,DATEADD(HOUR,4,SYSUTCDATETIME()))),NULL);

    /* ── OrderItems merchant2 ── */
    INSERT INTO dbo.OrderItems(order_id,food_item_id,item_name_snapshot,unit_price_snapshot,quantity,note)
    SELECT o.id,@m2_bur1,N'Burger Gà Nướng',65000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D0-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D1-001' UNION ALL
    SELECT o.id,@m2_cb2, N'Combo 2',        89000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D1-002' UNION ALL
    SELECT o.id,@m2_ga2, N'Gà Cay Special', 52000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D1-002' UNION ALL
    SELECT o.id,@m2_cb2, N'Combo 2',        89000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D2-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D3-001' UNION ALL
    SELECT o.id,@m2_bur2,N'Burger Double Stack',85000,1,NULL               FROM dbo.Orders o WHERE o.order_code=N'M2-D3-002' UNION ALL
    SELECT o.id,@m2_ga1, N'Gà Rán Original',45000,1,NULL                  FROM dbo.Orders o WHERE o.order_code=N'M2-D3-002' UNION ALL
    SELECT o.id,@m2_pep, N'Pepsi Lon',      18000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D3-002' UNION ALL
    SELECT o.id,@m2_cb2, N'Combo 2',        89000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D5-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D6-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D7-001' UNION ALL
    SELECT o.id,@m2_kh,  N'Khoai Tây Chiên',22000,1,NULL                  FROM dbo.Orders o WHERE o.order_code=N'M2-D7-001' UNION ALL
    SELECT o.id,@m2_cb2, N'Combo 2',        89000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D9-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D11-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D13-001' UNION ALL
    SELECT o.id,@m2_ga3, N'Gà Phủ Phô Mai', 58000,1,NULL                  FROM dbo.Orders o WHERE o.order_code=N'M2-D13-001' UNION ALL
    SELECT o.id,@m2_cb2, N'Combo 2',        89000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D15-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D17-001' UNION ALL
    SELECT o.id,@m2_cb1, N'Combo 1',        79000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D20-001' UNION ALL
    SELECT o.id,@m2_ga2, N'Gà Cay Special', 52000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D20-001' UNION ALL
    SELECT o.id,@m2_cb2, N'Combo 2',        89000,1,NULL                   FROM dbo.Orders o WHERE o.order_code=N'M2-D22-001';

    /* ── Status history merchant2 (DELIVERED orders) ── */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,
           DATEADD(MINUTE,-5,o.accepted_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m2,NULL,o.accepted_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m2,NULL,
           DATEADD(MINUTE,2,o.accepted_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PREPARING',N'READY_FOR_PICKUP',N'MERCHANT',@m2,NULL,o.ready_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'READY_FOR_PICKUP',N'PICKED_UP',N'SHIPPER',o.shipper_user_id,NULL,o.picked_up_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PICKED_UP',N'DELIVERED',N'SHIPPER',o.shipper_user_id,NULL,o.delivered_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'DELIVERED';

    /* CANCELLED */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,
           DATEADD(MINUTE,-3,o.cancelled_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'CANCELLED'
    UNION ALL
    SELECT o.id,N'CREATED',N'CANCELLED',N'CUSTOMER',o.customer_user_id,N'Khách hủy đơn',o.cancelled_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%' AND o.order_status=N'CANCELLED';

    /* PREPARING */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,DATEADD(MINUTE,-22,SYSUTCDATETIME())
    FROM dbo.Orders o WHERE o.order_code=N'M2-D0-001'
    UNION ALL
    SELECT o.id,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m2,NULL,DATEADD(MINUTE,-20,SYSUTCDATETIME())
    FROM dbo.Orders o WHERE o.order_code=N'M2-D0-001'
    UNION ALL
    SELECT o.id,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m2,NULL,o.accepted_at
    FROM dbo.Orders o WHERE o.order_code=N'M2-D0-001';

    /* ── Payments merchant2 ── */
    INSERT INTO dbo.PaymentTransactions(order_id,provider,amount,status,created_at)
    SELECT o.id,o.payment_method,o.total_amount,
           CASE WHEN o.order_status=N'DELIVERED' THEN N'SUCCESS'
                WHEN o.order_status=N'CANCELLED' THEN N'FAILED'
                ELSE N'INITIATED' END,
           CASE WHEN o.accepted_at IS NOT NULL THEN DATEADD(MINUTE,-5,o.accepted_at)
                ELSE SYSUTCDATETIME() END
    FROM dbo.Orders o WHERE o.order_code LIKE N'M2-%';

    /* ── Ratings merchant2 ── */
    INSERT INTO dbo.Ratings(order_id,rater_customer_id,rater_guest_id,target_type,target_user_id,stars,comment,created_at)
    SELECT o.id,o.customer_user_id,NULL,N'MERCHANT',@m2,
           CASE (o.id % 5)
               WHEN 0 THEN 5 WHEN 1 THEN 5 WHEN 2 THEN 4 WHEN 3 THEN 4 ELSE 3 END,
           CASE (o.id % 6)
               WHEN 0 THEN N'Combo ngon, đúng vị, giao nhanh lắm!'
               WHEN 1 THEN N'Gà giòn, không bị nguội khi nhận. 5 sao xứng đáng'
               WHEN 2 THEN N'Burger Double rất đã, lần sau đặt nữa'
               WHEN 3 THEN N'Đóng gói cẩn thận, combo giá hợp lý'
               WHEN 4 THEN N'Ổn, giao đúng giờ, không bị lộn đồ'
               ELSE      N'Sẽ đặt lại, quán phục vụ tốt!' END,
           DATEADD(MINUTE,20,o.delivered_at)
    FROM dbo.Orders o
    WHERE o.order_code LIKE N'M2-%'
      AND o.order_status=N'DELIVERED'
      AND NOT EXISTS (SELECT 1 FROM dbo.Ratings r WHERE r.order_id=o.id AND r.target_type=N'MERCHANT');

    /* ── Notifications merchant2 ── */
    INSERT INTO dbo.Notifications(user_id,guest_id,type,content,is_read,created_at)
    VALUES
    (@m2,NULL,N'ORDER_NEW',    N'Đơn M2-D0-001 (80,000đ) đang cần xử lý – Burger Gà Nướng',      0,DATEADD(MINUTE,-22,SYSUTCDATETIME())),
    (@m2,NULL,N'ORDER_NEW',    N'Đơn M2-D1-001 (94,000đ) đã được đặt – Combo 1',                  1,DATEADD(DAY,-1,DATEADD(HOUR,2,SYSUTCDATETIME()))),
    (@m2,NULL,N'ORDER_NEW',    N'Đơn M2-D1-002 (141,000đ) đã được đặt – Combo + Gà Cay',          1,DATEADD(DAY,-1,DATEADD(HOUR,6,SYSUTCDATETIME()))),
    (@m2,NULL,N'REVIEW',       N'Khách đánh giá 5⭐: "Combo ngon, giao nhanh lắm!"',                0,DATEADD(DAY,-1,DATEADD(HOUR,8,SYSUTCDATETIME()))),
    (@m2,NULL,N'ORDER_NEW',    N'Đơn M2-D3-002 (138,000đ) – Burger Double Stack + Gà Rán',        1,DATEADD(DAY,-3,DATEADD(HOUR,10,SYSUTCDATETIME()))),
    (@m2,NULL,N'ORDER_CANCELLED',N'Đơn M2-D6-001 (94,000đ) đã bị hủy bởi khách hàng',            1,DATEADD(DAY,-6,DATEADD(HOUR,8,SYSUTCDATETIME()))),
    (@m2,NULL,N'SYSTEM',       N'Doanh thu tháng 3 đạt 1.6 triệu đồng và đang tăng trưởng tốt!',  0,DATEADD(DAY,-2,SYSUTCDATETIME())),
    (@m2,NULL,N'SYSTEM',       N'Voucher COMBO20 của bạn đã được sử dụng 3 lần hôm nay',           0,DATEADD(DAY,-3,DATEADD(HOUR,12,SYSUTCDATETIME()))),
    (@m2,NULL,N'REVIEW',       N'Khách đánh giá 4⭐: "Burger Double rất đã, lần sau đặt nữa"',     0,DATEADD(DAY,-3,DATEADD(HOUR,12,SYSUTCDATETIME()))),
    (@m2,NULL,N'SYSTEM',       N'Gợi ý: Thêm ảnh món ăn để tăng 30% tỷ lệ chuyển đổi đơn hàng',  0,DATEADD(DAY,-1,SYSUTCDATETIME()));


    /* ================================================================
       MERCHANT 3 — Lollibee BT  (120 Xô Viết Nghệ Tĩnh, Bình Thạnh, APPROVED)
       Định hướng: Burger chuyên biệt, thêm món phụ và đồ uống
       ================================================================ */

    /* ── Categories cho merchant3 ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Khoai & Phụ')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m3,N'Khoai & Phụ',1,2);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Đồ Uống')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m3,N'Đồ Uống',1,3);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Tráng Miệng')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m3,N'Tráng Miệng',1,4);

    DECLARE @m3_cat_burger  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Burger');
    DECLARE @m3_cat_khoai   BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Khoai & Phụ');
    DECLARE @m3_cat_drink   BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Đồ Uống');
    DECLARE @m3_cat_dessert BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m3 AND name=N'Tráng Miệng');

    /* ── Food items cho merchant3 (8 món mới) ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Burger Phô Mai')
    INSERT INTO dbo.FoodItems(merchant_user_id,category_id,name,description,price,is_available,is_fried,calories,protein_g,carbs_g,fat_g)
    VALUES
    (@m3,@m3_cat_burger,N'Burger Phô Mai',      N'Burger gà với 2 lớp phô mai Cheddar nóng chảy',    65000,1,1,720,36,70,33),
    (@m3,@m3_cat_burger,N'Burger Tôm Giòn',     N'Tôm tươi tẩm bột panko chiên giòn',                70000,1,1,660,28,62,28),
    (@m3,@m3_cat_khoai, N'Khoai Tây Chiên',     N'Khoai cỡ vừa, vàng giòn đúng chuẩn',               20000,1,1,310,4,40,13),
    (@m3,@m3_cat_khoai, N'Bắp Ngô Nướng',       N'Bắp nướng bơ mặn thơm',                            18000,1,0,170,5,36,4),
    (@m3,@m3_cat_khoai, N'Salad Rau Tươi',      N'Rau xà lách, cà chua, dưa leo, sốt mè rang',       18000,1,0,75,3,10,3),
    (@m3,@m3_cat_drink, N'Coca Cola',            N'Coca Cola lạnh 330ml',                              18000,1,0,147,0,38,0),
    (@m3,@m3_cat_drink, N'Sprite Lon',           N'Sprite chanh mát lạnh 330ml',                       18000,1,0,130,0,33,0),
    (@m3,@m3_cat_dessert,N'Kem Vani Mềm',       N'Kem mềm thơm béo, phủ chocolate',                   22000,1,0,230,4,28,10);

    /* ── Food item IDs merchant3 ── */
    DECLARE @m3_bga  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Burger gà');
    DECLARE @m3_bca  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Burger cá');
    DECLARE @m3_bpm  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Burger Phô Mai');
    DECLARE @m3_btom BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Burger Tôm Giòn');
    DECLARE @m3_kh   BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Khoai Tây Chiên');
    DECLARE @m3_bap  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Bắp Ngô Nướng');
    DECLARE @m3_coca BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Coca Cola');
    DECLARE @m3_spr  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Sprite Lon');
    DECLARE @m3_kem  BIGINT = (SELECT TOP 1 id FROM dbo.FoodItems WHERE merchant_user_id=@m3 AND name=N'Kem Vani Mềm');

    /* ── 12 đơn hàng cho merchant3 ── */
    /*
       Subtotal check (fee cố định 12k vì gần hơn):
       M3-D0-001 : BurgerGà(55k)+Khoai(20k)                   = 75k + fee12 - disc0  = 87k  PREPARING
       M3-D1-001 : BurgerGà(55k)                              = 55k + fee12 - disc0  = 67k
       M3-D2-001 : BurgerCá(52k)+Khoai(20k)+Coca(18k)         = 90k + fee12 - disc10(FRYFREE) = 92k
       M3-D3-001 : BurgerGà(55k)+BurgerCá(52k)               = 107k + fee12 - disc10(FRYFREE) = 109k
       M3-D5-001 : BurgerGà(55k)+Khoai(20k)+Coca(18k)         = 93k + fee12 - disc10(FRYFREE)  = 95k
       M3-D6-001 : BurgerPhôMai(65k) CANCELLED                = 65k + fee12 - disc0  = 77k
       M3-D8-001 : BurgerTôm(70k)                            = 70k + fee12 - disc0  = 82k
       M3-D10-001: BurgerGà(55k)+Khoai(20k)                   = 75k + fee12 - disc0  = 87k
       M3-D12-001: BurgerPhôMai(65k)+Khoai(20k)+Sprite(18k)   = 103k + fee12 - disc10(FRYFREE) = 105k
       M3-D14-001: BurgerGà(55k)+BurgerCá(52k)+Khoai(20k)    = 127k + fee12 - disc10(FRYFREE) = 129k
       M3-D17-001: BurgerCá(52k)+Sprite(18k)                 = 70k + fee12 - disc0  = 82k
       M3-D20-001: BurgerGà(55k)                              = 55k + fee12 - disc0  = 67k
    */
    INSERT INTO dbo.Orders
    (order_code,customer_user_id,guest_id,merchant_user_id,shipper_user_id,
     receiver_name,receiver_phone,delivery_address_line,
     province_code,province_name,district_code,district_name,ward_code,ward_name,
     latitude,longitude,delivery_note,payment_method,payment_status,order_status,expires_at,
     subtotal_amount,delivery_fee,discount_amount,total_amount,
     accepted_at,ready_at,picked_up_at,delivered_at,cancelled_at)
    VALUES
    (N'M3-D0-001',@c1,NULL,@m3,@s2,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'UNPAID',N'PREPARING',NULL,
     75000,12000,0,87000,
     DATEADD(MINUTE,-25,SYSUTCDATETIME()),NULL,NULL,NULL,NULL),

    (N'M3-D1-001',@c4,NULL,@m3,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     55000,12000,0,67000,
     DATEADD(DAY,-1,DATEADD(HOUR,3,SYSUTCDATETIME())),
     DATEADD(DAY,-1,DATEADD(MINUTE,-20,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-1,DATEADD(MINUTE,-10,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-1,DATEADD(MINUTE,15,DATEADD(HOUR,4,SYSUTCDATETIME()))),NULL),

    (N'M3-D2-001',@c2,NULL,@m3,@s4,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     N'Không hành',N'VNPAY',N'PAID',N'DELIVERED',NULL,
     90000,12000,10000,92000,
     DATEADD(DAY,-2,DATEADD(HOUR,5,SYSUTCDATETIME())),
     DATEADD(DAY,-2,DATEADD(MINUTE,-22,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-2,DATEADD(MINUTE,-10,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-2,DATEADD(MINUTE,18,DATEADD(HOUR,6,SYSUTCDATETIME()))),NULL),

    (N'M3-D3-001',@c5,NULL,@m3,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     107000,12000,10000,109000,
     DATEADD(DAY,-3,DATEADD(HOUR,4,SYSUTCDATETIME())),
     DATEADD(DAY,-3,DATEADD(MINUTE,-25,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-3,DATEADD(MINUTE,-13,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-3,DATEADD(MINUTE,20,DATEADD(HOUR,5,SYSUTCDATETIME()))),NULL),

    (N'M3-D5-001',@c3,NULL,@m3,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     93000,12000,10000,95000,
     DATEADD(DAY,-5,DATEADD(HOUR,2,SYSUTCDATETIME())),
     DATEADD(DAY,-5,DATEADD(MINUTE,-20,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-5,DATEADD(MINUTE,-8,DATEADD(HOUR,3,SYSUTCDATETIME()))),
     DATEADD(DAY,-5,DATEADD(MINUTE,18,DATEADD(HOUR,3,SYSUTCDATETIME()))),NULL),

    (N'M3-D6-001',@c1,NULL,@m3,NULL,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'UNPAID',N'CANCELLED',NULL,
     65000,12000,0,77000,
     NULL,NULL,NULL,NULL,DATEADD(DAY,-6,DATEADD(HOUR,7,SYSUTCDATETIME()))),

    (N'M3-D8-001',@c4,NULL,@m3,@s3,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     70000,12000,0,82000,
     DATEADD(DAY,-8,DATEADD(HOUR,5,SYSUTCDATETIME())),
     DATEADD(DAY,-8,DATEADD(MINUTE,-22,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-8,DATEADD(MINUTE,-10,DATEADD(HOUR,6,SYSUTCDATETIME()))),
     DATEADD(DAY,-8,DATEADD(MINUTE,18,DATEADD(HOUR,6,SYSUTCDATETIME()))),NULL),

    (N'M3-D10-001',@c2,NULL,@m3,@s4,N'Lan',N'0900000013',N'34 Lê Lợi',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26737',N'Bến Thành',10.77216,106.69817,
     N'Giao giờ ăn trưa',N'COD',N'PAID',N'DELIVERED',NULL,
     75000,12000,0,87000,
     DATEADD(DAY,-10,DATEADD(HOUR,4,SYSUTCDATETIME())),
     DATEADD(DAY,-10,DATEADD(MINUTE,-23,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-10,DATEADD(MINUTE,-11,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-10,DATEADD(MINUTE,18,DATEADD(HOUR,5,SYSUTCDATETIME()))),NULL),

    (N'M3-D12-001',@c5,NULL,@m3,@s1,N'Phúc',N'0900000016',N'20 Nguyễn Văn Linh',
     N'48',N'Đà Nẵng',N'490',N'Hải Châu',N'20194',N'Phước Ninh',16.06060,108.22220,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     103000,12000,10000,105000,
     DATEADD(DAY,-12,DATEADD(HOUR,3,SYSUTCDATETIME())),
     DATEADD(DAY,-12,DATEADD(MINUTE,-22,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-12,DATEADD(MINUTE,-10,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-12,DATEADD(MINUTE,20,DATEADD(HOUR,4,SYSUTCDATETIME()))),NULL),

    (N'M3-D14-001',@c3,NULL,@m3,@s2,N'Minh',N'0900000014',N'88 Điện Biên Phủ',
     N'79',N'TP.HCM',N'769',N'Bình Thạnh',N'27145',N'Phường 21',10.80520,106.71290,
     NULL,N'VNPAY',N'PAID',N'DELIVERED',NULL,
     127000,12000,10000,129000,
     DATEADD(DAY,-14,DATEADD(HOUR,6,SYSUTCDATETIME())),
     DATEADD(DAY,-14,DATEADD(MINUTE,-25,DATEADD(HOUR,7,SYSUTCDATETIME()))),
     DATEADD(DAY,-14,DATEADD(MINUTE,-13,DATEADD(HOUR,7,SYSUTCDATETIME()))),
     DATEADD(DAY,-14,DATEADD(MINUTE,20,DATEADD(HOUR,7,SYSUTCDATETIME()))),NULL),

    (N'M3-D17-001',@c1,NULL,@m3,@s3,N'Huy',N'0900000012',N'12 Nguyễn Huệ',
     N'79',N'TP.HCM',N'760',N'Quận 1',N'26734',N'Bến Nghé',10.77653,106.70098,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     70000,12000,0,82000,
     DATEADD(DAY,-17,DATEADD(HOUR,4,SYSUTCDATETIME())),
     DATEADD(DAY,-17,DATEADD(MINUTE,-22,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-17,DATEADD(MINUTE,-10,DATEADD(HOUR,5,SYSUTCDATETIME()))),
     DATEADD(DAY,-17,DATEADD(MINUTE,18,DATEADD(HOUR,5,SYSUTCDATETIME()))),NULL),

    (N'M3-D20-001',@c4,NULL,@m3,@s4,N'Nga',N'0900000015',N'15 Võ Văn Ngân',
     N'79',N'TP.HCM',N'762',N'Thủ Đức',N'26848',N'Linh Chiểu',10.85140,106.75790,
     NULL,N'COD',N'PAID',N'DELIVERED',NULL,
     55000,12000,0,67000,
     DATEADD(DAY,-20,DATEADD(HOUR,3,SYSUTCDATETIME())),
     DATEADD(DAY,-20,DATEADD(MINUTE,-20,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-20,DATEADD(MINUTE,-8,DATEADD(HOUR,4,SYSUTCDATETIME()))),
     DATEADD(DAY,-20,DATEADD(MINUTE,18,DATEADD(HOUR,4,SYSUTCDATETIME()))),NULL);

    /* ── OrderItems merchant3 ── */
    INSERT INTO dbo.OrderItems(order_id,food_item_id,item_name_snapshot,unit_price_snapshot,quantity,note)
    SELECT o.id,@m3_bga, N'Burger gà',       55000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D0-001' UNION ALL
    SELECT o.id,@m3_kh,  N'Khoai Tây Chiên', 20000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D0-001' UNION ALL
    SELECT o.id,@m3_bga, N'Burger gà',       55000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D1-001' UNION ALL
    SELECT o.id,@m3_bca, N'Burger cá',       52000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D2-001' UNION ALL
    SELECT o.id,@m3_kh,  N'Khoai Tây Chiên', 20000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D2-001' UNION ALL
    SELECT o.id,@m3_coca,N'Coca Cola',        18000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D2-001' UNION ALL
    SELECT o.id,@m3_bga, N'Burger gà',       55000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D3-001' UNION ALL
    SELECT o.id,@m3_bca, N'Burger cá',       52000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D3-001' UNION ALL
    SELECT o.id,@m3_bga, N'Burger gà',       55000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D5-001' UNION ALL
    SELECT o.id,@m3_kh,  N'Khoai Tây Chiên', 20000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D5-001' UNION ALL
    SELECT o.id,@m3_coca,N'Coca Cola',        18000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D5-001' UNION ALL
    SELECT o.id,@m3_bpm, N'Burger Phô Mai',  65000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D6-001' UNION ALL
    SELECT o.id,@m3_btom,N'Burger Tôm Giòn', 70000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D8-001' UNION ALL
    SELECT o.id,@m3_bga, N'Burger gà',       55000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D10-001' UNION ALL
    SELECT o.id,@m3_kh,  N'Khoai Tây Chiên', 20000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D10-001' UNION ALL
    SELECT o.id,@m3_bpm, N'Burger Phô Mai',  65000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D12-001' UNION ALL
    SELECT o.id,@m3_kh,  N'Khoai Tây Chiên', 20000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D12-001' UNION ALL
    SELECT o.id,@m3_spr, N'Sprite Lon',       18000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D12-001' UNION ALL
    SELECT o.id,@m3_bga, N'Burger gà',       55000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D14-001' UNION ALL
    SELECT o.id,@m3_bca, N'Burger cá',       52000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D14-001' UNION ALL
    SELECT o.id,@m3_kh,  N'Khoai Tây Chiên', 20000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D14-001' UNION ALL
    SELECT o.id,@m3_bca, N'Burger cá',       52000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D17-001' UNION ALL
    SELECT o.id,@m3_spr, N'Sprite Lon',       18000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D17-001' UNION ALL
    SELECT o.id,@m3_bga, N'Burger gà',       55000,1,NULL FROM dbo.Orders o WHERE o.order_code=N'M3-D20-001';

    /* ── Status history merchant3 ── */
    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,DATEADD(MINUTE,-5,o.accepted_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m3,NULL,o.accepted_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m3,NULL,DATEADD(MINUTE,2,o.accepted_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PREPARING',N'READY_FOR_PICKUP',N'MERCHANT',@m3,NULL,o.ready_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'READY_FOR_PICKUP',N'PICKED_UP',N'SHIPPER',o.shipper_user_id,NULL,o.picked_up_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'DELIVERED'
    UNION ALL
    SELECT o.id,N'PICKED_UP',N'DELIVERED',N'SHIPPER',o.shipper_user_id,NULL,o.delivered_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'DELIVERED';

    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,DATEADD(MINUTE,-3,o.cancelled_at)
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'CANCELLED'
    UNION ALL
    SELECT o.id,N'CREATED',N'CANCELLED',N'CUSTOMER',o.customer_user_id,N'Khách hủy đơn',o.cancelled_at
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%' AND o.order_status=N'CANCELLED';

    INSERT INTO dbo.OrderStatusHistory(order_id,from_status,to_status,updated_by_role,updated_by_user_id,note,created_at)
    SELECT o.id,NULL,N'CREATED',N'CUSTOMER',o.customer_user_id,NULL,DATEADD(MINUTE,-27,SYSUTCDATETIME())
    FROM dbo.Orders o WHERE o.order_code=N'M3-D0-001'
    UNION ALL
    SELECT o.id,N'CREATED',N'MERCHANT_ACCEPTED',N'MERCHANT',@m3,NULL,DATEADD(MINUTE,-25,SYSUTCDATETIME())
    FROM dbo.Orders o WHERE o.order_code=N'M3-D0-001'
    UNION ALL
    SELECT o.id,N'MERCHANT_ACCEPTED',N'PREPARING',N'MERCHANT',@m3,NULL,o.accepted_at
    FROM dbo.Orders o WHERE o.order_code=N'M3-D0-001';

    /* ── Payments merchant3 ── */
    INSERT INTO dbo.PaymentTransactions(order_id,provider,amount,status,created_at)
    SELECT o.id,o.payment_method,o.total_amount,
           CASE WHEN o.order_status=N'DELIVERED' THEN N'SUCCESS'
                WHEN o.order_status=N'CANCELLED' THEN N'FAILED'
                ELSE N'INITIATED' END,
           CASE WHEN o.accepted_at IS NOT NULL THEN DATEADD(MINUTE,-5,o.accepted_at)
                ELSE SYSUTCDATETIME() END
    FROM dbo.Orders o WHERE o.order_code LIKE N'M3-%';

    /* ── Ratings merchant3 ── */
    INSERT INTO dbo.Ratings(order_id,rater_customer_id,rater_guest_id,target_type,target_user_id,stars,comment,created_at)
    SELECT o.id,o.customer_user_id,NULL,N'MERCHANT',@m3,
           CASE (o.id % 4) WHEN 0 THEN 5 WHEN 1 THEN 5 WHEN 2 THEN 4 ELSE 4 END,
           CASE (o.id % 5)
               WHEN 0 THEN N'Burger gà giòn đúng chuẩn, sốt ngon!'
               WHEN 1 THEN N'Burger cá tươi, không tanh, tuyệt vời'
               WHEN 2 THEN N'Khoai chiên giòn, ăn kèm burger mê lắm'
               WHEN 3 THEN N'Giao nhanh, burger vẫn giữ độ giòn'
               ELSE      N'Quán ngon, giá phải chăng, 5 sao!' END,
           DATEADD(MINUTE,25,o.delivered_at)
    FROM dbo.Orders o
    WHERE o.order_code LIKE N'M3-%'
      AND o.order_status=N'DELIVERED'
      AND NOT EXISTS (SELECT 1 FROM dbo.Ratings r WHERE r.order_id=o.id AND r.target_type=N'MERCHANT');

    /* ── Notifications merchant3 ── */
    INSERT INTO dbo.Notifications(user_id,guest_id,type,content,is_read,created_at)
    VALUES
    (@m3,NULL,N'ORDER_NEW',    N'Đơn M3-D0-001 (87,000đ) đang cần xử lý – Burger gà + Khoai', 0,DATEADD(MINUTE,-27,SYSUTCDATETIME())),
    (@m3,NULL,N'ORDER_NEW',    N'Đơn M3-D1-001 (67,000đ) đã được đặt – Burger gà',            1,DATEADD(DAY,-1,DATEADD(HOUR,3,SYSUTCDATETIME()))),
    (@m3,NULL,N'REVIEW',       N'Khách đánh giá 5⭐: "Burger gà giòn đúng chuẩn, sốt ngon!"', 0,DATEADD(DAY,-1,DATEADD(HOUR,5,SYSUTCDATETIME()))),
    (@m3,NULL,N'ORDER_CANCELLED',N'Đơn M3-D6-001 (77,000đ) đã bị hủy bởi khách hàng',        1,DATEADD(DAY,-6,DATEADD(HOUR,7,SYSUTCDATETIME()))),
    (@m3,NULL,N'REVIEW',       N'Khách đánh giá 4⭐: "Giao nhanh, burger vẫn giữ độ giòn"',   0,DATEADD(DAY,-2,DATEADD(HOUR,7,SYSUTCDATETIME()))),
    (@m3,NULL,N'SYSTEM',       N'Doanh thu tháng 3 đạt 950,000đ – tăng 18% so với tháng trước!',0,DATEADD(DAY,-2,SYSUTCDATETIME())),
    (@m3,NULL,N'SYSTEM',       N'Voucher FRYFREE đang rất phổ biến – đã dùng 28 lần trong 2 tuần',0,DATEADD(DAY,-3,SYSUTCDATETIME())),
    (@m3,NULL,N'SYSTEM',       N'Gợi ý thêm 1-2 món mới để tăng lượng đơn cuối tuần',         0,DATEADD(DAY,-1,SYSUTCDATETIME()));


    /* ================================================================
       MERCHANT 4 — Lollibee TD  (PENDING — catalog setup, no orders)
       Định hướng: Đồ Uống chuyên biệt – Trà Sữa, Sinh Tố, Cà Phê
       ================================================================ */

    /* ── Categories cho merchant4 ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Trà Sữa')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m4,N'Trà Sữa',1,2);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Sinh Tố')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m4,N'Sinh Tố',1,3);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Cà Phê')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m4,N'Cà Phê',1,4);

    DECLARE @m4_cat_nuoc  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Đồ uống');
    DECLARE @m4_cat_tra   BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Trà Sữa');
    DECLARE @m4_cat_sinh  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Sinh Tố');
    DECLARE @m4_cat_cafe  BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m4 AND name=N'Cà Phê');

    /* ── Food items cho merchant4 (8 món mới) ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.FoodItems WHERE merchant_user_id=@m4 AND name=N'Trà Sữa Trân Châu')
    INSERT INTO dbo.FoodItems(merchant_user_id,category_id,name,description,price,is_available,is_fried,calories,protein_g,carbs_g,fat_g)
    VALUES
    (@m4,@m4_cat_tra, N'Trà Sữa Trân Châu',   N'Trà sữa kem tươi với trân châu đen dẻo',           45000,1,0,380,5,65,9),
    (@m4,@m4_cat_tra, N'Trà Sữa Matcha',       N'Trà sữa matcha Nhật Bản, hương vị thanh mát',       48000,1,0,350,6,58,8),
    (@m4,@m4_cat_tra, N'Trà Sữa Khoai Môn',    N'Trà sữa khoai môn tím ngọt thơm đặc trưng',        45000,1,0,400,5,70,9),
    (@m4,@m4_cat_tra, N'Trà Sữa Hồng Trà',     N'Hồng trà Ceylon thơm kết hợp kem béo mịn',         42000,1,0,320,4,55,8),
    (@m4,@m4_cat_sinh,N'Sinh Tố Xoài',         N'Xoài chín tươi xay nhuyễn với sữa đặc',            38000,1,0,310,3,68,3),
    (@m4,@m4_cat_sinh,N'Sinh Tố Dâu',          N'Dâu tây tươi xay với sữa chua, thơm mát',          40000,1,0,290,4,60,4),
    (@m4,@m4_cat_sinh,N'Sinh Tố Bơ',           N'Bơ Đắk Lắk chín kem xay cùng sữa tươi nguyên kem',45000,1,0,450,5,42,28),
    (@m4,@m4_cat_cafe, N'Cà Phê Sữa Đá',       N'Cà phê robusta pha phin truyền thống với sữa đặc', 28000,1,0,180,3,30,5),
    (@m4,@m4_cat_cafe, N'Bạc Xỉu Đá',          N'Ít cà phê, nhiều sữa – dịu nhẹ hơn',               28000,1,0,200,4,35,5),
    (@m4,@m4_cat_cafe, N'Caffe Latte',          N'Espresso hòa cùng sữa tươi nóng mịn bọt',          38000,1,0,150,5,18,6);

    /* Cập nhật lại food items Trà đào và Coca đã có */
    UPDATE dbo.FoodItems SET description=N'Trà đào mát lạnh – đặc sản của quán'
    WHERE merchant_user_id=@m4 AND name=N'Trà đào';
    UPDATE dbo.FoodItems SET description=N'Nước giải khát Coca lạnh 330ml'
    WHERE merchant_user_id=@m4 AND name=N'Coca';


    /* ================================================================
       MERCHANT 5 — Lollibee DN  (PENDING — catalog setup, no orders)
       Định hướng: Tráng Miệng – Bánh Ngọt, Chè, Kem
       ================================================================ */

    /* ── Categories cho merchant5 ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Bánh Ngọt')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m5,N'Bánh Ngọt',1,2);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Chè')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m5,N'Chè',1,3);
    IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Kem')
        INSERT INTO dbo.Categories(merchant_user_id,name,is_active,sort_order) VALUES(@m5,N'Kem',1,4);

    DECLARE @m5_cat_dessert BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Tráng miệng');
    DECLARE @m5_cat_banh    BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Bánh Ngọt');
    DECLARE @m5_cat_che     BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Chè');
    DECLARE @m5_cat_kem     BIGINT = (SELECT id FROM dbo.Categories WHERE merchant_user_id=@m5 AND name=N'Kem');

    /* ── Food items cho merchant5 (6 món mới) ── */
    IF NOT EXISTS (SELECT 1 FROM dbo.FoodItems WHERE merchant_user_id=@m5 AND name=N'Bánh Tiramisu')
    INSERT INTO dbo.FoodItems(merchant_user_id,category_id,name,description,price,is_available,is_fried,calories,protein_g,carbs_g,fat_g)
    VALUES
    (@m5,@m5_cat_banh,N'Bánh Tiramisu',       N'Bánh tiramisu kiểu Ý, cacao đắng, mascarpone béo',  45000,1,0,420,7,48,22),
    (@m5,@m5_cat_banh,N'Bánh Crepe Sầu Riêng',N'Bánh crepe lớp mỏng nhân kem sầu riêng Ri6',        55000,1,0,510,8,60,25),
    (@m5,@m5_cat_banh,N'Bánh Mousse Dâu',     N'Mousse dâu tây mịn mượt, trang trí dâu tươi',       48000,1,0,380,6,52,15),
    (@m5,@m5_cat_che, N'Chè Ba Màu',          N'Chè ba màu truyền thống: đậu đỏ, đậu xanh, thạch',  28000,1,0,280,6,58,3),
    (@m5,@m5_cat_che, N'Chè Thái',            N'Chè Thái đầy màu sắc với dừa tươi, hạt lựu',        32000,1,0,310,4,65,5),
    (@m5,@m5_cat_che, N'Chè Khúc Bạch',       N'Chè khúc bạch mát lạnh, thạch hoa quả tươi',        35000,1,0,290,5,60,4),
    (@m5,@m5_cat_kem, N'Kem Dâu',             N'Kem dâu tây tươi một cầu, béo mịn',                 25000,1,0,210,3,30,9),
    (@m5,@m5_cat_kem, N'Kem Sô-cô-la',        N'Kem sô-cô-la Bỉ đậm đà',                            25000,1,0,230,4,32,10),
    (@m5,@m5_cat_kem, N'Kem Dừa',             N'Kem dừa Bến Tre thơm béo tự nhiên',                 28000,1,0,240,3,34,11);

    COMMIT TRAN;

    /* ── Tóm tắt ── */
    DECLARE @s_m2id BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000003');
    DECLARE @s_m3id BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000004');
    DECLARE @s_m4id BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000005');
    DECLARE @s_m5id BIGINT = (SELECT id FROM dbo.Users WHERE phone=N'0900000006');
    DECLARE @s_m2cat  INT = (SELECT COUNT(*) FROM dbo.Categories WHERE merchant_user_id=@s_m2id);
    DECLARE @s_m2fi   INT = (SELECT COUNT(*) FROM dbo.FoodItems   WHERE merchant_user_id=@s_m2id);
    DECLARE @s_m2ord  INT = (SELECT COUNT(*) FROM dbo.Orders      WHERE merchant_user_id=@s_m2id);
    DECLARE @s_m3cat  INT = (SELECT COUNT(*) FROM dbo.Categories WHERE merchant_user_id=@s_m3id);
    DECLARE @s_m3fi   INT = (SELECT COUNT(*) FROM dbo.FoodItems   WHERE merchant_user_id=@s_m3id);
    DECLARE @s_m3ord  INT = (SELECT COUNT(*) FROM dbo.Orders      WHERE merchant_user_id=@s_m3id);
    DECLARE @s_m4cat  INT = (SELECT COUNT(*) FROM dbo.Categories WHERE merchant_user_id=@s_m4id);
    DECLARE @s_m4fi   INT = (SELECT COUNT(*) FROM dbo.FoodItems   WHERE merchant_user_id=@s_m4id);
    DECLARE @s_m5cat  INT = (SELECT COUNT(*) FROM dbo.Categories WHERE merchant_user_id=@s_m5id);
    DECLARE @s_m5fi   INT = (SELECT COUNT(*) FROM dbo.FoodItems   WHERE merchant_user_id=@s_m5id);
    PRINT N'✅ MERCHANT ENRICHMENT completed!';
    PRINT N'   Merchant2 categories: ' + CAST(@s_m2cat  AS NVARCHAR(10));
    PRINT N'   Merchant2 food items: '  + CAST(@s_m2fi   AS NVARCHAR(10));
    PRINT N'   Merchant2 orders (all): '+ CAST(@s_m2ord  AS NVARCHAR(10));
    PRINT N'   Merchant3 categories: ' + CAST(@s_m3cat  AS NVARCHAR(10));
    PRINT N'   Merchant3 food items: '  + CAST(@s_m3fi   AS NVARCHAR(10));
    PRINT N'   Merchant3 orders (all): '+ CAST(@s_m3ord  AS NVARCHAR(10));
    PRINT N'   Merchant4 categories: ' + CAST(@s_m4cat  AS NVARCHAR(10));
    PRINT N'   Merchant4 food items: '  + CAST(@s_m4fi   AS NVARCHAR(10));
    PRINT N'   Merchant5 categories: ' + CAST(@s_m5cat  AS NVARCHAR(10));
    PRINT N'   Merchant5 food items: '  + CAST(@s_m5fi   AS NVARCHAR(10));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    PRINT N'❌ ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
