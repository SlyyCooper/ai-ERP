#!/usr/bin/env bash
#
# erp_db.sh
#
# INTRODUCTION
#
# This script is deliberately expansive, lengthy, and elaborate in order to craft
# a PostgreSQL 16 database schema that surpasses the features and complexity
# of typical enterprise resource planning (ERP) systems such as NetSuite. The
# purpose is to offer a schema that would please even the most demanding CFOs,
# CPAs, ERP directors, finance administrators, supply chain managers, HR
# professionals, and C-level executives, while also catering to IT, operations,
# and project management teams. 
#
# If you're looking for a system that covers (and sometimes exceeds) the breadth
# of standard ERP features, including multi-company/subsidiary management,
# advanced supply chain functionality, production (manufacturing),
# multi-currency accounting, budgeting and forecasting, tax compliance,
# payroll, CRM, marketing, projects, warehouse management, quality control,
# user access controls, approval workflows, and more, this script is designed
# to demonstrate precisely that. 
#
# The approach here is to group related modules in the schema. Each module
# may include specialized tables, references to other modules, and additional
# detail or metadata that would ordinarily be required in a robust, real-world
# ERP solution. Furthermore, we have included a variety of features that go
# above and beyond simpler implementations: for example, advanced analytics
# placeholders, sophisticated audit logging, and references to potential
# integration points (such as EDI or external APIs). 
#
# While there's theoretically no upper limit to how extensive such a schema
# could become, this script is designed to be used as a starting framework for
# production. You could easily prune, modify, and adapt it to your exact needs,
# but it should be a fairly comprehensive illustration of what an ultra-high-end
# ERP database might include.
#
# HOW TO USE:
#
#   1) Make this script executable on your system:
#         chmod +x erp_db.sh
#
#   2) Execute it:
#         ./erp_db.sh
#
#   3) The script will:
#       - pull the PostgreSQL 16 Docker image (if it’s not present locally),
#       - run a container named "extreme_erp_container" on port 5433
#         (since 5432 might already be in use by another PostgreSQL instance),
#       - create an extensive ERP schema in a database named "extreme_erp_database"
#         under credentials erp_user / erp_pass,
#       - populate it with a wide variety of sample data that illustrate how
#         the different modules interrelate.
#
# Keep in mind that in a real production environment, you would likely want
# to manage environment variables, secrets, and Docker configurations using
# best practices (e.g., Docker Compose, Vault, Kubernetes Secrets, etc.).
# Also, be sure to review or test any generated code in a safe environment,
# especially if dealing with highly sensitive data.
#
# Enjoy exploring this sprawling demonstration of an ERP schema that strives
# to surpass even NetSuite in its breadth and detail!
#

#========================================================================================
# 1. CONFIGURATION
#========================================================================================

CONTAINER_NAME="extreme_erp_container"
POSTGRES_VERSION="16"
HOST_PORT=5433           # Use a custom host port to avoid conflicts with local Postgres
CONTAINER_PORT=5432      # Container’s internal port
POSTGRES_USER="erp_user"
POSTGRES_PASSWORD="erp_pass"
POSTGRES_DB="extreme_erp_database"

echo "==========================================================================================================="
echo "     EXTREME ERP DATABASE SETUP SCRIPT - A Comprehensive, Expansive, Non-Concise, Production-Ready DB     "
echo "==========================================================================================================="

#========================================================================================
# 2. PULL THE POSTGRESQL 16 IMAGE
#========================================================================================
echo "Pulling postgres:${POSTGRES_VERSION} Docker image if not already available..."
docker pull "postgres:${POSTGRES_VERSION}"

#========================================================================================
# 3. RUN THE CONTAINER
#========================================================================================
echo "Starting container '${CONTAINER_NAME}' on host port ${HOST_PORT}..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  -e POSTGRES_USER="${POSTGRES_USER}" \
  -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
  -e POSTGRES_DB="${POSTGRES_DB}" \
  "postgres:${POSTGRES_VERSION}"

# Give PostgreSQL some time to spin up and finalize its initialization
echo "Allowing the PostgreSQL container a few seconds to finish initializing..."
sleep 10

#========================================================================================
# 4. CREATE AND POPULATE THE SCHEMA
#========================================================================================
echo "Executing the massive schema creation and data population within the container..."

docker exec -i "${CONTAINER_NAME}" psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" <<EOF

--
-- We begin with an extremely elaborate schema that covers (and often exceeds)
-- features found in enterprise-grade ERP systems. Each module is commented
-- in detail to provide insight into how these structures might be used.
--

-- ======================================================================================
-- MODULE 0: EXTREME GLOBAL SETTINGS & EXTENSIONS
-- ======================================================================================
-- In a production environment, you might enable various PostgreSQL extensions
-- (like pgcrypto, PostGIS, Timescale, or others). For demonstration, let's
-- enable a couple that might be beneficial for advanced analytics or security.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- This table could serve as a central repository for system-wide settings,
-- toggles, or configuration parameters.
CREATE TABLE IF NOT EXISTS global_settings (
    setting_key         VARCHAR(255) PRIMARY KEY,
    setting_value       VARCHAR(255),
    description         TEXT,
    last_modified       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================================
-- MODULE 1: COMPANIES, SUBSIDIARIES, AND LEGAL ENTITIES
-- ======================================================================================
-- In a large global enterprise, you often have multiple legal entities under a 
-- single corporate umbrella. We'll elaborate with even more attributes than before.

CREATE TABLE IF NOT EXISTS companies (
    company_id              SERIAL PRIMARY KEY,
    external_company_uuid   UUID DEFAULT uuid_generate_v4(),  -- a globally unique ID 
    company_name            VARCHAR(255) NOT NULL,
    company_legal_name      VARCHAR(255),
    tax_id_number           VARCHAR(50),       -- e.g. EIN in the US, or local equivalent
    incorporation_country   VARCHAR(100),
    base_currency_code      VARCHAR(10),       -- for the main currency 
    default_language        VARCHAR(10),       -- e.g., 'en', 'de', 'fr', etc.
    address_line1           VARCHAR(255),
    address_line2           VARCHAR(255),
    city                    VARCHAR(100),
    state_province          VARCHAR(100),
    country                 VARCHAR(100),
    postal_code             VARCHAR(50),
    phone                   VARCHAR(50),
    email                   VARCHAR(100),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active               BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS subsidiaries (
    subsidiary_id           SERIAL PRIMARY KEY,
    external_subsidiary_uuid UUID DEFAULT uuid_generate_v4(),
    subsidiary_name         VARCHAR(255) NOT NULL,
    parent_company_id       INT NOT NULL,
    local_currency_code     VARCHAR(10),
    local_language          VARCHAR(10),
    region                  VARCHAR(100),      -- e.g. EMEA, APAC, AMER
    address_line1           VARCHAR(255),
    address_line2           VARCHAR(255),
    city                    VARCHAR(100),
    state_province          VARCHAR(100),
    country                 VARCHAR(100),
    postal_code             VARCHAR(50),
    phone                   VARCHAR(50),
    email                   VARCHAR(100),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active               BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_subsidiary_company
        FOREIGN KEY (parent_company_id) REFERENCES companies(company_id)
);

-- ======================================================================================
-- MODULE 2: CURRENCIES, EXCHANGE RATES, AND FINANCIAL CONFIG
-- ======================================================================================
-- Many multinational corporations require robust multi-currency support with dynamic 
-- exchange rate tracking. We can elaborate by adding support for historical rates,
-- default rate types, or custom rate classifications.

CREATE TABLE IF NOT EXISTS currencies (
    currency_id             SERIAL PRIMARY KEY,
    external_currency_uuid  UUID DEFAULT uuid_generate_v4(),
    currency_code           VARCHAR(10) NOT NULL UNIQUE,  -- e.g., USD, EUR, GBP
    currency_name           VARCHAR(100) NOT NULL,        -- e.g., 'US Dollar'
    symbol                  VARCHAR(10),
    decimal_places          INT DEFAULT 2,                -- standard decimal precision
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active               BOOLEAN DEFAULT TRUE
);

-- Exchange rate types might be "spot rate", "monthly average", "historical",
-- "budget rate", or similar. This allows us to store multiple rate definitions
-- for the same pair of currencies over time.
CREATE TABLE IF NOT EXISTS exchange_rate_types (
    rate_type_id            SERIAL PRIMARY KEY,
    rate_type_name          VARCHAR(50) NOT NULL,  -- e.g. 'Spot', 'Monthly Avg'
    description             TEXT,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    rate_id                 SERIAL PRIMARY KEY,
    base_currency_id        INT NOT NULL,
    quote_currency_id       INT NOT NULL,
    rate_type_id            INT NOT NULL,   -- references the exchange_rate_types table
    exchange_rate           NUMERIC(18,8) NOT NULL,
    effective_date          DATE NOT NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exchange_base
        FOREIGN KEY (base_currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_exchange_quote
        FOREIGN KEY (quote_currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_exchange_type
        FOREIGN KEY (rate_type_id) REFERENCES exchange_rate_types(rate_type_id)
);

-- ======================================================================================
-- MODULE 3: ENTERPRISE USER MANAGEMENT & AUTHORIZATION
-- ======================================================================================
-- In many ERP systems, there's an internal concept of user accounts or an
-- integration with a Single Sign-On (SSO) provider. For demonstration, we'll
-- store some user metadata here, along with roles and permissions. 
-- This might be distinct from system-level database users for actual connections,
-- but it represents the application-level user profiles.

CREATE TABLE IF NOT EXISTS erp_users (
    erp_user_id            SERIAL PRIMARY KEY,
    external_user_uuid     UUID DEFAULT uuid_generate_v4(),
    username               VARCHAR(100) NOT NULL UNIQUE,
    email                  VARCHAR(255) NOT NULL,
    password_hash          VARCHAR(255), -- in real life, you'd store a salted hash
    full_name              VARCHAR(255),
    company_id             INT,          -- user might be assigned to a company
    subsidiary_id          INT,
    is_super_admin         BOOLEAN DEFAULT FALSE, -- can do anything
    is_active              BOOLEAN DEFAULT TRUE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at          TIMESTAMP,
    CONSTRAINT fk_erpuser_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_erpuser_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

-- Roles define groups of permissions or job responsibilities, such as
-- "Accounting Manager", "Sales Rep", "IT Admin," or any custom role that the 
-- organization might create.
CREATE TABLE IF NOT EXISTS erp_roles (
    erp_role_id           SERIAL PRIMARY KEY,
    role_name             VARCHAR(100) NOT NULL UNIQUE,
    role_description      TEXT,
    created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- A many-to-many relationship between users and roles, since a single user
-- can hold multiple roles, and a single role can be assigned to multiple users.
CREATE TABLE IF NOT EXISTS erp_user_roles (
    user_role_id           SERIAL PRIMARY KEY,
    erp_user_id            INT NOT NULL,
    erp_role_id            INT NOT NULL,
    assigned_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_userroles_user
        FOREIGN KEY (erp_user_id) REFERENCES erp_users(erp_user_id),
    CONSTRAINT fk_userroles_role
        FOREIGN KEY (erp_role_id) REFERENCES erp_roles(erp_role_id)
);

-- Permissions define finer-grained capabilities. For instance, a permission
-- might be "VIEW_INVOICES", "CREATE_INVOICES", "APPROVE_PURCHASE_ORDERS", or 
-- "RUN_PAYROLL".
CREATE TABLE IF NOT EXISTS erp_permissions (
    permission_id          SERIAL PRIMARY KEY,
    permission_name        VARCHAR(100) NOT NULL UNIQUE,
    permission_description TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Another many-to-many: roles can have multiple permissions, and permissions
-- can be assigned to multiple roles.
CREATE TABLE IF NOT EXISTS erp_role_permissions (
    role_permission_id     SERIAL PRIMARY KEY,
    erp_role_id            INT NOT NULL,
    permission_id          INT NOT NULL,
    granted_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rolepermissions_role
        FOREIGN KEY (erp_role_id) REFERENCES erp_roles(erp_role_id),
    CONSTRAINT fk_rolepermissions_permission
        FOREIGN KEY (permission_id) REFERENCES erp_permissions(permission_id)
);

-- ======================================================================================
-- MODULE 4: CHART OF ACCOUNTS & GL ADVANCED
-- ======================================================================================
-- Here we expand upon the Chart of Accounts concept to include classification,
-- IFRS/GAAP flags, or potential dimension attributes for more sophisticated
-- analysis. 

CREATE TABLE IF NOT EXISTS chart_of_accounts (
    account_id             SERIAL PRIMARY KEY,
    external_account_uuid  UUID DEFAULT uuid_generate_v4(),
    account_name           VARCHAR(255) NOT NULL,
    account_type           VARCHAR(50) NOT NULL,   -- e.g., Asset, Liability, Equity, Revenue, Expense
    account_subtype        VARCHAR(50),           -- more granular classification if needed
    parent_account_id      INT,                   -- hierarchical relationships
    account_code           VARCHAR(50),           -- numeric or alphanumeric code
    is_postable            BOOLEAN DEFAULT TRUE,  -- some accounts are headers and not postable
    ifrs_compliant         BOOLEAN DEFAULT TRUE,
    gaap_compliant         BOOLEAN DEFAULT TRUE,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    active                 BOOLEAN DEFAULT TRUE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_account_parent
        FOREIGN KEY (parent_account_id) REFERENCES chart_of_accounts(account_id),
    CONSTRAINT fk_account_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_account_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

-- Sometimes, organizations want further extensibility for each account:
-- storing custom attributes, usage rules, or classification codes.
CREATE TABLE IF NOT EXISTS chart_of_accounts_attributes (
    coa_attribute_id       SERIAL PRIMARY KEY,
    account_id             INT NOT NULL,
    attribute_name         VARCHAR(100) NOT NULL,
    attribute_value        VARCHAR(255),
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_coa_attr_account
        FOREIGN KEY (account_id) REFERENCES chart_of_accounts(account_id)
);

-- ======================================================================================
-- MODULE 5: FISCAL CALENDARS & PERIODS
-- ======================================================================================
-- We expand this by adding additional potential columns, such as "adjusting_period"
-- flags or "locked" statuses to indicate if a period is closed for additional postings.

CREATE TABLE IF NOT EXISTS fiscal_calendars (
    fiscal_calendar_id     SERIAL PRIMARY KEY,
    external_calendar_uuid UUID DEFAULT uuid_generate_v4(),
    fiscal_year            INT NOT NULL,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_locked              BOOLEAN DEFAULT FALSE,  -- could indicate the entire year is locked
    CONSTRAINT fk_calendar_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_calendar_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS fiscal_periods (
    period_id              SERIAL PRIMARY KEY,
    external_period_uuid   UUID DEFAULT uuid_generate_v4(),
    fiscal_calendar_id     INT NOT NULL,
    period_name            VARCHAR(50) NOT NULL,   -- e.g. 'Q1', 'Period01', 'Month01'
    start_date             DATE NOT NULL,
    end_date               DATE NOT NULL,
    is_adjusting_period    BOOLEAN DEFAULT FALSE,
    is_closed              BOOLEAN DEFAULT FALSE,  -- locked for new postings
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fp_calendar
        FOREIGN KEY (fiscal_calendar_id) REFERENCES fiscal_calendars(fiscal_calendar_id)
);

-- ======================================================================================
-- MODULE 6: TAX CODES & TAX JURISDICTIONS
-- ======================================================================================
-- We can expand the concept of taxes to multiple jurisdictions or multi-level taxes.

CREATE TABLE IF NOT EXISTS tax_jurisdictions (
    tax_jurisdiction_id    SERIAL PRIMARY KEY,
    jurisdiction_name      VARCHAR(100) NOT NULL,  -- e.g. 'California', 'Federal US', 'EU'
    country                VARCHAR(100),
    region_state           VARCHAR(100),
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tax_codes (
    tax_code_id            SERIAL PRIMARY KEY,
    external_tax_code_uuid UUID DEFAULT uuid_generate_v4(),
    tax_code_name          VARCHAR(50) NOT NULL,     -- e.g. 'VAT10', 'CA_SALES_TAX'
    tax_rate               NUMERIC(6,4) NOT NULL,    -- e.g. 0.1000 (10%)
    is_recoverable         BOOLEAN DEFAULT TRUE,     -- Some taxes are recoverable, some not
    jurisdiction_id        INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tax_jurisdiction
        FOREIGN KEY (jurisdiction_id) REFERENCES tax_jurisdictions(tax_jurisdiction_id)
);

-- ======================================================================================
-- MODULE 7: DEPARTMENTS, LOCATIONS, CLASSES (ADDITIONAL DIMENSIONS)
-- ======================================================================================
-- Some systems have additional classification dimensions beyond department or
-- location, sometimes called 'Class' or 'Profit Center,' for further segmentation.

CREATE TABLE IF NOT EXISTS departments (
    department_id          SERIAL PRIMARY KEY,
    department_name        VARCHAR(100) NOT NULL,
    department_code        VARCHAR(50),
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active              BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_departments_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_departments_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS locations (
    location_id            SERIAL PRIMARY KEY,
    location_name          VARCHAR(100) NOT NULL,
    address_line1          VARCHAR(255),
    address_line2          VARCHAR(255),
    city                   VARCHAR(100),
    state_province         VARCHAR(100),
    country                VARCHAR(100),
    postal_code            VARCHAR(50),
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active              BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_locations_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_locations_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS classes (
    class_id               SERIAL PRIMARY KEY,
    class_name             VARCHAR(100) NOT NULL,
    class_description      TEXT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active              BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_classes_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_classes_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

-- ======================================================================================
-- MODULE 8: HR, PAYROLL, AND TIME TRACKING
-- ======================================================================================
-- We'll expand to include more robust employee data and add a table for employee
-- benefits, as well as a table for advanced payroll items or pay types (like bonuses,
-- commissions, or reimbursements).

CREATE TABLE IF NOT EXISTS employees (
    employee_id            SERIAL PRIMARY KEY,
    external_employee_uuid UUID DEFAULT uuid_generate_v4(),
    first_name             VARCHAR(100) NOT NULL,
    last_name              VARCHAR(100) NOT NULL,
    department_id          INT,
    location_id            INT,
    class_id               INT,
    subsidiary_id          INT,
    company_id             INT NOT NULL,
    hired_date             DATE,
    email                  VARCHAR(255),
    phone                  VARCHAR(50),
    job_title              VARCHAR(100),
    pay_rate               NUMERIC(15,2) DEFAULT 0,   -- base pay rate
    pay_type               VARCHAR(50) DEFAULT 'Hourly',  -- or 'Salary', etc.
    is_active              BOOLEAN DEFAULT TRUE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_emp_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_emp_location
        FOREIGN KEY (location_id) REFERENCES locations(location_id),
    CONSTRAINT fk_emp_class
        FOREIGN KEY (class_id) REFERENCES classes(class_id),
    CONSTRAINT fk_emp_subsidiary
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id),
    CONSTRAINT fk_emp_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id)
);

CREATE TABLE IF NOT EXISTS pay_types (
    pay_type_id            SERIAL PRIMARY KEY,
    pay_type_name          VARCHAR(100) NOT NULL,  -- e.g. 'Base Salary', 'Hourly', 'Overtime', 'Bonus'
    default_rate_modifier  NUMERIC(5,2) DEFAULT 1, -- e.g., 1.5 for time-and-a-half
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS employee_benefits (
    benefit_id             SERIAL PRIMARY KEY,
    employee_id            INT NOT NULL,
    benefit_type           VARCHAR(100),          -- e.g. 'Health Insurance', '401k', 'Dental'
    benefit_details        TEXT,
    effective_date         DATE,
    expiration_date        DATE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_eb_employee
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS pay_periods (
    pay_period_id          SERIAL PRIMARY KEY,
    period_name            VARCHAR(50) NOT NULL,   -- e.g., 'Bi-Weekly #1 - Jan 2024'
    start_date             DATE NOT NULL,
    end_date               DATE NOT NULL,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payroll_runs (
    payroll_run_id         SERIAL PRIMARY KEY,
    pay_period_id          INT NOT NULL,
    company_id             INT NOT NULL,
    run_date               DATE NOT NULL,
    status                 VARCHAR(50) DEFAULT 'Pending',  -- e.g., Pending, Processed, Paid
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pr_payperiod
        FOREIGN KEY (pay_period_id) REFERENCES pay_periods(pay_period_id),
    CONSTRAINT fk_pr_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id)
);

CREATE TABLE IF NOT EXISTS payroll_run_details (
    payroll_detail_id      SERIAL PRIMARY KEY,
    payroll_run_id         INT NOT NULL,
    employee_id            INT NOT NULL,
    pay_type_id            INT,  -- e.g., base pay, bonus, etc.
    hours_worked           NUMERIC(10,2) DEFAULT 0,
    gross_pay              NUMERIC(15,2) DEFAULT 0,
    tax_withheld           NUMERIC(15,2) DEFAULT 0,
    net_pay                NUMERIC(15,2)
        GENERATED ALWAYS AS (gross_pay - tax_withheld) STORED,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prd_run
        FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(payroll_run_id),
    CONSTRAINT fk_prd_employee
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT fk_prd_paytype
        FOREIGN KEY (pay_type_id) REFERENCES pay_types(pay_type_id)
);

CREATE TABLE IF NOT EXISTS timesheets (
    timesheet_id           SERIAL PRIMARY KEY,
    employee_id            INT NOT NULL,
    start_date             DATE NOT NULL,
    end_date               DATE NOT NULL,
    total_hours            NUMERIC(10,2) DEFAULT 0,
    approved               BOOLEAN DEFAULT FALSE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_timesheet_employee
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS time_entries (
    time_entry_id          SERIAL PRIMARY KEY,
    timesheet_id           INT NOT NULL,
    entry_date             DATE NOT NULL,
    hours_worked           NUMERIC(5,2) NOT NULL,
    task_description       TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_timeentry_timesheet
        FOREIGN KEY (timesheet_id) REFERENCES timesheets(timesheet_id)
);

-- ======================================================================================
-- MODULE 9: CUSTOMERS, VENDORS, CRM, AND SUPPLIER RELATIONSHIPS
-- ======================================================================================
-- We'll expand customers and vendors to include potential CRM fields such as
-- lead source, or vendor rating. Also adding a table for marketing campaigns
-- or leads.

CREATE TABLE IF NOT EXISTS customers (
    customer_id            SERIAL PRIMARY KEY,
    external_customer_uuid UUID DEFAULT uuid_generate_v4(),
    customer_name          VARCHAR(255) NOT NULL,
    contact_name           VARCHAR(100),
    phone                  VARCHAR(50),
    email                  VARCHAR(100),
    billing_address        VARCHAR(255),
    shipping_address       VARCHAR(255),
    customer_since         DATE,
    lead_source            VARCHAR(100), -- e.g. 'Web', 'Trade Show'
    credit_limit           NUMERIC(15,2) DEFAULT 0,
    currency_id            INT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active              BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_cust_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_cust_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_cust_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS vendors (
    vendor_id              SERIAL PRIMARY KEY,
    external_vendor_uuid   UUID DEFAULT uuid_generate_v4(),
    vendor_name            VARCHAR(255) NOT NULL,
    contact_name           VARCHAR(100),
    phone                  VARCHAR(50),
    email                  VARCHAR(100),
    address                VARCHAR(255),
    vendor_since           DATE,
    vendor_rating          VARCHAR(50),   -- e.g. 'Gold', 'Silver', 'Preferred'
    currency_id            INT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active              BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_vendor_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_vendor_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_vendor_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS marketing_campaigns (
    campaign_id            SERIAL PRIMARY KEY,
    campaign_name          VARCHAR(255) NOT NULL,
    start_date             DATE,
    end_date               DATE,
    budget                 NUMERIC(15,2) DEFAULT 0,
    actual_spend           NUMERIC(15,2) DEFAULT 0,
    campaign_owner_id      INT,  -- link to erp_users or employees?
    description            TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS leads (
    lead_id                SERIAL PRIMARY KEY,
    lead_name              VARCHAR(255) NOT NULL,
    phone                  VARCHAR(50),
    email                  VARCHAR(255),
    lead_source            VARCHAR(100),
    campaign_id            INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status                 VARCHAR(50) DEFAULT 'New',  -- e.g. 'New', 'Contacted', 'Qualified', 'Lost'
    CONSTRAINT fk_lead_campaign
        FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(campaign_id)
);

-- ======================================================================================
-- MODULE 10: ITEMS, INVENTORY, WAREHOUSE, AND MANUFACTURING
-- ======================================================================================
-- We expand upon previous inventory details by adding tables for 
-- Bill of Materials, manufacturing orders (if relevant), lot/serial tracking, etc.

CREATE TABLE IF NOT EXISTS items (
    item_id                SERIAL PRIMARY KEY,
    external_item_uuid     UUID DEFAULT uuid_generate_v4(),
    item_name              VARCHAR(255) NOT NULL,
    item_sku               VARCHAR(100),
    item_type              VARCHAR(50),   -- e.g. 'Inventory', 'Service', 'Assembly', 'Kit'
    cost                   NUMERIC(15,2) DEFAULT 0,
    price                  NUMERIC(15,2) DEFAULT 0,
    currency_id            INT,
    uom                    VARCHAR(50) DEFAULT 'EA', -- unit of measure, e.g. 'EA' for each
    reorder_point          NUMERIC(15,2) DEFAULT 0,
    preferred_vendor_id    INT,
    weight                 NUMERIC(15,2) DEFAULT 0,     -- shipping weight
    length                 NUMERIC(15,2) DEFAULT 0,
    width                  NUMERIC(15,2) DEFAULT 0,
    height                 NUMERIC(15,2) DEFAULT 0,
    active                 BOOLEAN DEFAULT TRUE,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_item_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_item_vendor
        FOREIGN KEY (preferred_vendor_id) REFERENCES vendors(vendor_id),
    CONSTRAINT fk_item_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_item_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

-- Warehouse or distribution center references might also be stored in 'locations'
-- but we can add a specific table to handle multiple warehouses if needed.

CREATE TABLE IF NOT EXISTS inventory_transactions (
    transaction_id         SERIAL PRIMARY KEY,
    item_id                INT NOT NULL,
    location_id            INT NOT NULL,
    transaction_type       VARCHAR(50) NOT NULL, -- e.g. 'Adjustment', 'Receipt', 'Shipment'
    quantity               NUMERIC(15,2) NOT NULL,
    transaction_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reference_number       VARCHAR(100),         -- link to PO, SO, or other doc
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_invtran_item
        FOREIGN KEY (item_id) REFERENCES items(item_id),
    CONSTRAINT fk_invtran_location
        FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

-- For manufacturing or assembly items, a Bill of Materials (BOM) is needed:
CREATE TABLE IF NOT EXISTS bill_of_materials (
    bom_id                 SERIAL PRIMARY KEY,
    parent_item_id         INT NOT NULL,         -- The finished good or assembly
    child_item_id          INT NOT NULL,         -- The component
    quantity_per           NUMERIC(15,2) NOT NULL DEFAULT 1,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bom_parent
        FOREIGN KEY (parent_item_id) REFERENCES items(item_id),
    CONSTRAINT fk_bom_child
        FOREIGN KEY (child_item_id) REFERENCES items(item_id)
);

-- Manufacturing Orders to track production requests and statuses:
CREATE TABLE IF NOT EXISTS manufacturing_orders (
    mo_id                  SERIAL PRIMARY KEY,
    mo_number              VARCHAR(50) NOT NULL UNIQUE,
    parent_item_id         INT NOT NULL,
    scheduled_start_date   DATE,
    scheduled_end_date     DATE,
    actual_start_date      DATE,
    actual_end_date        DATE,
    status                 VARCHAR(50) DEFAULT 'Planned', -- e.g. 'Planned', 'In Progress', 'Completed'
    quantity_planned       NUMERIC(15,2) NOT NULL DEFAULT 0,
    quantity_completed     NUMERIC(15,2) NOT NULL DEFAULT 0,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mo_parent_item
        FOREIGN KEY (parent_item_id) REFERENCES items(item_id)
);

-- Lot/Serial Tracking:
CREATE TABLE IF NOT EXISTS lot_serials (
    lot_serial_id          SERIAL PRIMARY KEY,
    item_id                INT NOT NULL,
    lot_or_serial_number   VARCHAR(100) NOT NULL,
    expiration_date        DATE,
    creation_date          DATE DEFAULT CURRENT_DATE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ls_item
        FOREIGN KEY (item_id) REFERENCES items(item_id)
);

CREATE TABLE IF NOT EXISTS lot_serial_transactions (
    ls_transaction_id      SERIAL PRIMARY KEY,
    lot_serial_id          INT NOT NULL,
    transaction_id         INT NOT NULL,  -- links to inventory_transactions
    quantity               NUMERIC(15,2) NOT NULL,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_lst_ls
        FOREIGN KEY (lot_serial_id) REFERENCES lot_serials(lot_serial_id),
    CONSTRAINT fk_lst_txn
        FOREIGN KEY (transaction_id) REFERENCES inventory_transactions(transaction_id)
);

-- ======================================================================================
-- MODULE 11: ORDER-TO-CASH (Sales Orders, Invoices, Payments)
-- ======================================================================================
-- We expand upon these tables to account for advanced features such as partial shipments,
-- partial invoices, multiple fulfillment steps, etc.

CREATE TABLE IF NOT EXISTS sales_orders (
    so_id                  SERIAL PRIMARY KEY,
    external_so_uuid       UUID DEFAULT uuid_generate_v4(),
    so_number              VARCHAR(50) NOT NULL,
    customer_id            INT NOT NULL,
    so_date                DATE NOT NULL,
    status                 VARCHAR(50) DEFAULT 'Pending',
    currency_id            INT,
    period_id              INT,     -- if posted to a certain accounting period
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    total_amount           NUMERIC(15,2) DEFAULT 0,
    discount_amount        NUMERIC(15,2) DEFAULT 0,
    tax_amount             NUMERIC(15,2) DEFAULT 0,
    shipping_amount        NUMERIC(15,2) DEFAULT 0,
    notes                  TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_so_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_so_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_so_period
        FOREIGN KEY (period_id) REFERENCES fiscal_periods(period_id),
    CONSTRAINT fk_so_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_so_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS so_lines (
    so_line_id             SERIAL PRIMARY KEY,
    so_id                  INT NOT NULL,
    item_id                INT NOT NULL,
    quantity               NUMERIC(15,2) NOT NULL DEFAULT 1,
    unit_price             NUMERIC(15,2) NOT NULL DEFAULT 0,
    tax_code_id            INT,
    discount_rate          NUMERIC(5,2) DEFAULT 0,    -- e.g. 10.00 means 10%
    total_line             NUMERIC(15,2)
        GENERATED ALWAYS AS (
            (quantity * unit_price) - ((quantity * unit_price) * (discount_rate/100))
        ) STORED,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_soline_so
        FOREIGN KEY (so_id) REFERENCES sales_orders(so_id),
    CONSTRAINT fk_soline_item
        FOREIGN KEY (item_id) REFERENCES items(item_id),
    CONSTRAINT fk_soline_tax
        FOREIGN KEY (tax_code_id) REFERENCES tax_codes(tax_code_id)
);

CREATE TABLE IF NOT EXISTS invoices (
    invoice_id             SERIAL PRIMARY KEY,
    external_invoice_uuid  UUID DEFAULT uuid_generate_v4(),
    invoice_number         VARCHAR(50) NOT NULL,
    customer_id            INT NOT NULL,
    invoice_date           DATE NOT NULL,
    due_date               DATE,
    status                 VARCHAR(50) DEFAULT 'Unpaid',
    currency_id            INT,
    so_id                  INT,   
    period_id              INT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    total_amount           NUMERIC(15,2) DEFAULT 0,
    discount_amount        NUMERIC(15,2) DEFAULT 0,
    tax_amount             NUMERIC(15,2) DEFAULT 0,
    shipping_amount        NUMERIC(15,2) DEFAULT 0,
    notes                  TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inv_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_inv_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_inv_so
        FOREIGN KEY (so_id) REFERENCES sales_orders(so_id),
    CONSTRAINT fk_inv_period
        FOREIGN KEY (period_id) REFERENCES fiscal_periods(period_id),
    CONSTRAINT fk_inv_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_inv_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS invoice_lines (
    invoice_line_id        SERIAL PRIMARY KEY,
    invoice_id             INT NOT NULL,
    item_id                INT NOT NULL,
    quantity               NUMERIC(15,2) NOT NULL DEFAULT 1,
    unit_price             NUMERIC(15,2) NOT NULL DEFAULT 0,
    tax_code_id            INT,
    discount_rate          NUMERIC(5,2) DEFAULT 0,  -- e.g. 5 means 5%
    total_line             NUMERIC(15,2)
        GENERATED ALWAYS AS (
            (quantity * unit_price) - ((quantity * unit_price) * (discount_rate/100))
        ) STORED,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_invline_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
    CONSTRAINT fk_invline_item
        FOREIGN KEY (item_id) REFERENCES items(item_id),
    CONSTRAINT fk_invline_tax
        FOREIGN KEY (tax_code_id) REFERENCES tax_codes(tax_code_id)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id             SERIAL PRIMARY KEY,
    external_payment_uuid  UUID DEFAULT uuid_generate_v4(),
    payment_number         VARCHAR(50) NOT NULL,
    payment_method_id      INT,
    bank_account_id        INT,
    payment_date           DATE NOT NULL,
    amount                 NUMERIC(15,2) NOT NULL,
    currency_id            INT,
    customer_id            INT,  
    vendor_id              INT,
    invoice_id             INT,
    bill_id                INT,
    period_id              INT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes                  TEXT,
    CONSTRAINT fk_pay_method
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id),
    CONSTRAINT fk_pay_bank
        FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(bank_account_id),
    CONSTRAINT fk_pay_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_pay_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_pay_vendor
        FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id),
    CONSTRAINT fk_pay_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
    CONSTRAINT fk_pay_bill
        FOREIGN KEY (bill_id) REFERENCES bills(bill_id),
    CONSTRAINT fk_pay_period
        FOREIGN KEY (period_id) REFERENCES fiscal_periods(period_id),
    CONSTRAINT fk_pay_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_pay_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

-- ======================================================================================
-- MODULE 12: PROCURE-TO-PAY (Purchase Orders, Bills, Vendor Payments)
-- ======================================================================================

CREATE TABLE IF NOT EXISTS purchase_orders (
    po_id                  SERIAL PRIMARY KEY,
    external_po_uuid       UUID DEFAULT uuid_generate_v4(),
    po_number              VARCHAR(50) NOT NULL,
    vendor_id              INT NOT NULL,
    po_date                DATE NOT NULL,
    status                 VARCHAR(50) DEFAULT 'Pending',
    total_amount           NUMERIC(15,2) DEFAULT 0,
    discount_amount        NUMERIC(15,2) DEFAULT 0,
    tax_amount             NUMERIC(15,2) DEFAULT 0,
    shipping_amount        NUMERIC(15,2) DEFAULT 0,
    currency_id            INT,
    period_id              INT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    notes                  TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_po_vendor
        FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id),
    CONSTRAINT fk_po_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_po_period
        FOREIGN KEY (period_id) REFERENCES fiscal_periods(period_id),
    CONSTRAINT fk_po_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_po_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS po_lines (
    po_line_id             SERIAL PRIMARY KEY,
    po_id                  INT NOT NULL,
    item_id                INT NOT NULL,
    quantity               NUMERIC(15,2) NOT NULL DEFAULT 1,
    unit_cost              NUMERIC(15,2) NOT NULL DEFAULT 0,
    tax_code_id            INT,
    discount_rate          NUMERIC(5,2) DEFAULT 0,
    total_line             NUMERIC(15,2)
        GENERATED ALWAYS AS (
            (quantity * unit_cost) - ((quantity * unit_cost) * (discount_rate/100))
        ) STORED,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_polines_po
        FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id),
    CONSTRAINT fk_polines_item
        FOREIGN KEY (item_id) REFERENCES items(item_id),
    CONSTRAINT fk_polines_tax
        FOREIGN KEY (tax_code_id) REFERENCES tax_codes(tax_code_id)
);

CREATE TABLE IF NOT EXISTS bills (
    bill_id                SERIAL PRIMARY KEY,
    external_bill_uuid     UUID DEFAULT uuid_generate_v4(),
    bill_number            VARCHAR(50) NOT NULL,
    vendor_id              INT NOT NULL,
    bill_date              DATE NOT NULL,
    due_date               DATE,
    status                 VARCHAR(50) DEFAULT 'Unpaid',
    currency_id            INT,
    po_id                  INT,  
    period_id              INT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    total_amount           NUMERIC(15,2) DEFAULT 0,
    discount_amount        NUMERIC(15,2) DEFAULT 0,
    tax_amount             NUMERIC(15,2) DEFAULT 0,
    shipping_amount        NUMERIC(15,2) DEFAULT 0,
    notes                  TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bill_vendor
        FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id),
    CONSTRAINT fk_bill_currency
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    CONSTRAINT fk_bill_po
        FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id),
    CONSTRAINT fk_bill_period
        FOREIGN KEY (period_id) REFERENCES fiscal_periods(period_id),
    CONSTRAINT fk_bill_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_bill_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS bill_lines (
    bill_line_id           SERIAL PRIMARY KEY,
    bill_id                INT NOT NULL,
    item_id                INT NOT NULL,
    quantity               NUMERIC(15,2) NOT NULL DEFAULT 1,
    unit_cost              NUMERIC(15,2) NOT NULL DEFAULT 0,
    tax_code_id            INT,
    discount_rate          NUMERIC(5,2) DEFAULT 0,
    total_line             NUMERIC(15,2)
        GENERATED ALWAYS AS (
            (quantity * unit_cost) - ((quantity * unit_cost) * (discount_rate/100))
        ) STORED,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_billline_bill
        FOREIGN KEY (bill_id) REFERENCES bills(bill_id),
    CONSTRAINT fk_billline_item
        FOREIGN KEY (item_id) REFERENCES items(item_id),
    CONSTRAINT fk_billline_tax
        FOREIGN KEY (tax_code_id) REFERENCES tax_codes(tax_code_id)
);

-- ======================================================================================
-- MODULE 13: GENERAL LEDGER AND JOURNAL ENTRIES (with multi-dimensional postings)
-- ======================================================================================

CREATE TABLE IF NOT EXISTS journal_entries (
    journal_entry_id       SERIAL PRIMARY KEY,
    external_je_uuid       UUID DEFAULT uuid_generate_v4(),
    entry_date             DATE NOT NULL,
    description            TEXT,
    period_id              INT NOT NULL,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    posted                 BOOLEAN DEFAULT FALSE,   -- indicates if posted to the GL
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_je_period
        FOREIGN KEY (period_id) REFERENCES fiscal_periods(period_id),
    CONSTRAINT fk_je_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_je_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS journal_line_items (
    line_item_id           SERIAL PRIMARY KEY,
    journal_entry_id       INT NOT NULL,
    account_id             INT NOT NULL,
    debit                  NUMERIC(15,2) DEFAULT 0,
    credit                 NUMERIC(15,2) DEFAULT 0,
    department_id          INT,
    location_id            INT,
    class_id               INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_jli_je
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(journal_entry_id),
    CONSTRAINT fk_jli_account
        FOREIGN KEY (account_id) REFERENCES chart_of_accounts(account_id),
    CONSTRAINT fk_jli_dept
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_jli_location
        FOREIGN KEY (location_id) REFERENCES locations(location_id),
    CONSTRAINT fk_jli_class
        FOREIGN KEY (class_id) REFERENCES classes(class_id)
);

-- ======================================================================================
-- MODULE 14: PROJECTS, TASKS, AND JOB COSTING
-- ======================================================================================
-- We enhance the project concept with job costing tables, resource allocations,
-- and more.

CREATE TABLE IF NOT EXISTS projects (
    project_id             SERIAL PRIMARY KEY,
    external_project_uuid  UUID DEFAULT uuid_generate_v4(),
    project_name           VARCHAR(255) NOT NULL,
    customer_id            INT,        -- if it's a customer project
    start_date             DATE,
    end_date               DATE,
    status                 VARCHAR(50) DEFAULT 'Active',
    budget                 NUMERIC(15,2) DEFAULT 0,
    actual_cost            NUMERIC(15,2) DEFAULT 0,
    project_manager_id     INT,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_proj_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_proj_mgr
        FOREIGN KEY (project_manager_id) REFERENCES employees(employee_id),
    CONSTRAINT fk_proj_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_proj_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE IF NOT EXISTS project_tasks (
    task_id                SERIAL PRIMARY KEY,
    project_id             INT NOT NULL,
    task_name              VARCHAR(255) NOT NULL,
    assigned_to            INT,
    start_date             DATE,
    end_date               DATE,
    status                 VARCHAR(50) DEFAULT 'Not Started', 
    estimated_hours        NUMERIC(10,2) DEFAULT 0,
    actual_hours           NUMERIC(10,2) DEFAULT 0,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_task_project
        FOREIGN KEY (project_id) REFERENCES projects(project_id),
    CONSTRAINT fk_task_assignee
        FOREIGN KEY (assigned_to) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS project_costs (
    project_cost_id        SERIAL PRIMARY KEY,
    project_id             INT NOT NULL,
    cost_description       VARCHAR(255),
    cost_amount            NUMERIC(15,2) NOT NULL DEFAULT 0,
    cost_date              DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pc_project
        FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

-- ======================================================================================
-- MODULE 15: BUDGETING, FORECASTING, AND CONSOLIDATIONS
-- ======================================================================================
-- We expand on budgets to support departmental, project-based, or class-based budgets,
-- plus a consolidation table for multi-subsidiary roll-ups.

CREATE TABLE IF NOT EXISTS budgets (
    budget_id              SERIAL PRIMARY KEY,
    fiscal_calendar_id     INT NOT NULL,
    department_id          INT,
    location_id            INT,
    class_id               INT,
    subsidiary_id          INT,
    company_id             INT NOT NULL,
    budget_name            VARCHAR(255),
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_final               BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_budget_cal
        FOREIGN KEY (fiscal_calendar_id) REFERENCES fiscal_calendars(fiscal_calendar_id),
    CONSTRAINT fk_budget_dept
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_budget_loc
        FOREIGN KEY (location_id) REFERENCES locations(location_id),
    CONSTRAINT fk_budget_class
        FOREIGN KEY (class_id) REFERENCES classes(class_id),
    CONSTRAINT fk_budget_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id),
    CONSTRAINT fk_budget_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id)
);

CREATE TABLE IF NOT EXISTS budget_lines (
    budget_line_id         SERIAL PRIMARY KEY,
    budget_id              INT NOT NULL,
    account_id             INT NOT NULL,
    period_id              INT NOT NULL,
    budget_amount          NUMERIC(15,2) DEFAULT 0,
    notes                  TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_budgetline_budget
        FOREIGN KEY (budget_id) REFERENCES budgets(budget_id),
    CONSTRAINT fk_budgetline_account
        FOREIGN KEY (account_id) REFERENCES chart_of_accounts(account_id),
    CONSTRAINT fk_budgetline_period
        FOREIGN KEY (period_id) REFERENCES fiscal_periods(period_id)
);

CREATE TABLE IF NOT EXISTS consolidations (
    consolidation_id       SERIAL PRIMARY KEY,
    consolidation_date     DATE NOT NULL,
    company_id             INT NOT NULL,
    subsidiary_id          INT,
    ledger_type            VARCHAR(50) DEFAULT 'Actual',  -- could be 'Actual', 'Budget', 'Forecast'
    currency_id            INT,  -- for consolidated currency
    exchange_rate          NUMERIC(18,8),
    consolidated_amount    NUMERIC(15,2) DEFAULT 0,
    notes                  TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_consolidation_company
        FOREIGN KEY (company_id) REFERENCES companies(company_id),
    CONSTRAINT fk_consolidation_sub
        FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id),
    CONSTRAINT fk_consolidation_curr
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
);

-- ======================================================================================
-- MODULE 16: APPROVAL WORKFLOWS
-- ======================================================================================
-- For advanced systems, we might implement a flexible approval workflow for 
-- purchase orders, sales orders, bills, etc.

CREATE TABLE IF NOT EXISTS approval_workflows (
    workflow_id            SERIAL PRIMARY KEY,
    workflow_name          VARCHAR(255) NOT NULL,
    document_type          VARCHAR(50) NOT NULL, -- e.g. 'PO', 'SO', 'Bill', 'Invoice'
    sequence_number        INT NOT NULL,         -- step in the workflow
    approval_role_id       INT NOT NULL,         -- who is responsible for approving
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active              BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_aw_role
        FOREIGN KEY (approval_role_id) REFERENCES erp_roles(erp_role_id)
);

CREATE TABLE IF NOT EXISTS approval_requests (
    approval_request_id    SERIAL PRIMARY KEY,
    workflow_id            INT NOT NULL,
    document_id            INT NOT NULL,  -- ID of the PO, SO, Bill, etc.
    status                 VARCHAR(50) DEFAULT 'Pending', -- e.g. 'Pending', 'Approved', 'Rejected'
    requested_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_rejected_at   TIMESTAMP,
    notes                  TEXT,
    CONSTRAINT fk_ar_workflow
        FOREIGN KEY (workflow_id) REFERENCES approval_workflows(workflow_id)
);

-- ======================================================================================
-- MODULE 17: SHIPPING, LOGISTICS, AND FULFILLMENT
-- ======================================================================================
-- For organizations that ship products, you might have carriers, shipping addresses,
-- shipment tracking, etc.

CREATE TABLE IF NOT EXISTS carriers (
    carrier_id             SERIAL PRIMARY KEY,
    carrier_name           VARCHAR(255) NOT NULL,  -- e.g. UPS, FedEx, DHL
    contact_info           VARCHAR(255),
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shipments (
    shipment_id            SERIAL PRIMARY KEY,
    so_id                  INT,   -- if shipping against a sales order
    carrier_id             INT,
    tracking_number        VARCHAR(100),
    shipment_date          DATE,
    status                 VARCHAR(50) DEFAULT 'In Transit',
    shipping_cost          NUMERIC(15,2) DEFAULT 0,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_shipment_so
        FOREIGN KEY (so_id) REFERENCES sales_orders(so_id),
    CONSTRAINT fk_shipment_carrier
        FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id)
);

-- ======================================================================================
-- MODULE 18: DOCUMENT MANAGEMENT
-- ======================================================================================
-- Systems often need to store attachments or references to external documents
-- (in a real environment, you might store only references to a file server or S3).

CREATE TABLE IF NOT EXISTS document_attachments (
    attachment_id          SERIAL PRIMARY KEY,
    document_type          VARCHAR(50) NOT NULL, -- e.g. 'Invoice', 'PO'
    document_id            INT NOT NULL,
    file_name              VARCHAR(255),
    file_path              VARCHAR(255), -- or S3 URL, etc.
    uploaded_by            INT,         -- reference to erp_users
    uploaded_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes                  TEXT,
    CONSTRAINT fk_docattach_user
        FOREIGN KEY (uploaded_by) REFERENCES erp_users(erp_user_id)
);

-- ======================================================================================
-- MODULE 19: AUDIT LOGS & SYSTEM INTEGRATIONS
-- ======================================================================================
-- We'll create an advanced audit log capturing system. Also a table for external
-- integrations or scheduled tasks, if we want to track them in the DB.

CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id               SERIAL PRIMARY KEY,
    user_email             VARCHAR(255),
    table_name             VARCHAR(100),
    action_taken           VARCHAR(50),   -- e.g., INSERT, UPDATE, DELETE
    record_pk              VARCHAR(255),  -- primary key ID of the record changed
    old_data               JSONB,         -- storing the pre-change data
    new_data               JSONB,         -- storing the post-change data
    timestamp              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS system_integrations (
    integration_id         SERIAL PRIMARY KEY,
    integration_name       VARCHAR(255) NOT NULL, -- e.g. 'Salesforce Integration', 'EDI Connection'
    api_endpoint_url       VARCHAR(255),
    auth_token             VARCHAR(255),
    last_run_timestamp     TIMESTAMP,
    status                 VARCHAR(50) DEFAULT 'Idle',
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS scheduled_jobs (
    job_id                 SERIAL PRIMARY KEY,
    job_name               VARCHAR(255) NOT NULL,
    job_schedule           VARCHAR(50),  -- e.g. cron expression
    job_action             VARCHAR(255), -- a function or script reference
    last_run_timestamp     TIMESTAMP,
    next_run_timestamp     TIMESTAMP,
    status                 VARCHAR(50) DEFAULT 'Scheduled',
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================================================
-- MODULE 20: MASSIVE SAMPLE DATA INSERTS 
-- ======================================================================================
-- Despite the scale of this schema, let's insert some demonstration data into 
-- various key tables so that if you spin this up, you have references to test
-- relationships.

-- Global Settings
INSERT INTO global_settings (setting_key, setting_value, description)
VALUES
    ('SystemName', 'SuperERP UltraMax', 'Global system name displayed to end-users'),
    ('DefaultLanguage', 'en', 'Fallback language for the interface'),
    ('EnableAdvancedTaxes', 'true', 'Enable advanced multi-jurisdiction tax calculations')
ON CONFLICT (setting_key) DO NOTHING;

-- Companies
INSERT INTO companies (company_name, company_legal_name, tax_id_number, incorporation_country,
                       base_currency_code, default_language, city, country, email)
VALUES
    ('Super Global Corp', 'Super Global Corporation LLC', '12-3456789', 'USA', 'USD', 'en', 'New York', 'USA', 'info@superglobal.com')
ON CONFLICT DO NOTHING;

-- Subsidiaries
INSERT INTO subsidiaries (subsidiary_name, parent_company_id, local_currency_code, local_language, region, city, country)
SELECT 'Super Global EU', 1, 'EUR', 'de', 'EMEA', 'Berlin', 'Germany'
WHERE NOT EXISTS (SELECT 1 FROM subsidiaries WHERE subsidiary_name='Super Global EU');

-- Currencies
INSERT INTO currencies (currency_code, currency_name, symbol, decimal_places)
VALUES
    ('USD', 'US Dollar', '\$', 2),
    ('EUR', 'Euro', '€', 2),
    ('GBP', 'British Pound', '£', 2),
    ('JPY', 'Japanese Yen', '¥', 0)
ON CONFLICT DO NOTHING;

-- Exchange Rate Types
INSERT INTO exchange_rate_types (rate_type_name, description)
VALUES
    ('Spot', 'Daily spot rate used for immediate transactions'),
    ('Monthly Average', 'Monthly average rate for accounting calculations'),
    ('Historical', 'Specific historical rate on a certain date')
ON CONFLICT DO NOTHING;

-- Insert sample exchange rates
INSERT INTO exchange_rates (base_currency_id, quote_currency_id, rate_type_id, exchange_rate, effective_date)
SELECT
    (SELECT currency_id FROM currencies WHERE currency_code='USD'),
    (SELECT currency_id FROM currencies WHERE currency_code='EUR'),
    (SELECT rate_type_id FROM exchange_rate_types WHERE rate_type_name='Spot'),
    0.90, '2025-01-01'
WHERE NOT EXISTS (
    SELECT 1 FROM exchange_rates
    WHERE base_currency_id=(SELECT currency_id FROM currencies WHERE currency_code='USD')
      AND quote_currency_id=(SELECT currency_id FROM currencies WHERE currency_code='EUR')
      AND rate_type_id=(SELECT rate_type_id FROM exchange_rate_types WHERE rate_type_name='Spot')
      AND effective_date='2025-01-01'
);

-- ERP Users
INSERT INTO erp_users (username, email, full_name, company_id, is_super_admin)
VALUES
    ('admin', 'admin@superglobal.com', 'System Administrator', 1, TRUE)
ON CONFLICT DO NOTHING;

-- ERP Roles
INSERT INTO erp_roles (role_name, role_description)
VALUES
    ('Administrator', 'Full access to all modules'),
    ('Accounting Manager', 'Manages all finance and accounting transactions'),
    ('Sales Manager', 'Manages sales process and approvals'),
    ('Warehouse Manager', 'Oversees inventory and logistics')
ON CONFLICT DO NOTHING;

-- ERP Permissions
INSERT INTO erp_permissions (permission_name, permission_description)
VALUES
    ('MANAGE_USERS', 'Ability to create and modify ERP Users'),
    ('VIEW_FINANCIALS', 'Ability to view all financial data'),
    ('EDIT_FINANCIALS', 'Ability to modify financial data'),
    ('APPROVE_PURCHASE_ORDERS', 'Ability to approve or reject POs')
ON CONFLICT DO NOTHING;

-- Assign roles to user (admin user gets the Administrator role)
INSERT INTO erp_user_roles (erp_user_id, erp_role_id)
SELECT (SELECT erp_user_id FROM erp_users WHERE username='admin'),
       (SELECT erp_role_id FROM erp_roles WHERE role_name='Administrator')
WHERE NOT EXISTS (
    SELECT 1 FROM erp_user_roles
    WHERE erp_user_id=(SELECT erp_user_id FROM erp_users WHERE username='admin')
      AND erp_role_id=(SELECT erp_role_id FROM erp_roles WHERE role_name='Administrator')
);

-- Assign permissions to roles
INSERT INTO erp_role_permissions (erp_role_id, permission_id)
SELECT 
    (SELECT erp_role_id FROM erp_roles WHERE role_name='Administrator'),
    permission_id
FROM erp_permissions
WHERE NOT EXISTS (
    SELECT 1 FROM erp_role_permissions
    WHERE erp_role_id=(SELECT erp_role_id FROM erp_roles WHERE role_name='Administrator')
      AND permission_id=erp_permissions.permission_id
);

-- Chart of Accounts
INSERT INTO chart_of_accounts (account_name, account_type, company_id, account_code)
VALUES
    ('Cash', 'Asset', 1, '1000'),
    ('Accounts Receivable', 'Asset', 1, '1100'),
    ('Inventory', 'Asset', 1, '1200'),
    ('Fixed Assets', 'Asset', 1, '1500'),
    ('Accounts Payable', 'Liability', 1, '2000'),
    ('Credit Cards Payable', 'Liability', 1, '2050'),
    ('Taxes Payable', 'Liability', 1, '2100'),
    ('Common Stock', 'Equity', 1, '3000'),
    ('Retained Earnings', 'Equity', 1, '3100'),
    ('Revenue', 'Revenue', 1, '4000'),
    ('Cost of Goods Sold', 'Expense', 1, '5000'),
    ('Operating Expenses', 'Expense', 1, '6000')
ON CONFLICT DO NOTHING;

-- Fiscal Calendars & Periods
INSERT INTO fiscal_calendars (fiscal_year, company_id)
VALUES (2025, 1)
ON CONFLICT DO NOTHING;

-- Insert periods for 2025
INSERT INTO fiscal_periods (fiscal_calendar_id, period_name, start_date, end_date)
SELECT fc.fiscal_calendar_id, q.period_name, q.start_date, q.end_date
FROM (VALUES
    ('Q1', '2025-01-01', '2025-03-31'),
    ('Q2', '2025-04-01', '2025-06-30'),
    ('Q3', '2025-07-01', '2025-09-30'),
    ('Q4', '2025-10-01', '2025-12-31')
) as q(period_name, start_date, end_date),
     fiscal_calendars fc
WHERE fc.fiscal_year = 2025
  AND NOT EXISTS (
    SELECT 1 FROM fiscal_periods fp
    WHERE fp.fiscal_calendar_id = fc.fiscal_calendar_id
      AND fp.period_name = q.period_name
);

-- Tax Jurisdictions & Codes
INSERT INTO tax_jurisdictions (jurisdiction_name, country, region_state)
VALUES
    ('California State Tax', 'USA', 'California'),
    ('US Federal Tax', 'USA', 'Federal'),
    ('European VAT Region', 'Europe', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO tax_codes (tax_code_name, tax_rate, jurisdiction_id)
SELECT 'CA_SALES_TAX', 0.075, (SELECT tax_jurisdiction_id FROM tax_jurisdictions WHERE jurisdiction_name='California State Tax')
WHERE NOT EXISTS (SELECT 1 FROM tax_codes WHERE tax_code_name='CA_SALES_TAX');

-- Departments and Locations
INSERT INTO departments (department_name, company_id)
VALUES
    ('Finance', 1),
    ('Sales', 1),
    ('IT', 1),
    ('Operations', 1)
ON CONFLICT DO NOTHING;

INSERT INTO locations (location_name, city, company_id)
VALUES
    ('Main Warehouse', 'New York', 1),
    ('West Coast DC', 'Los Angeles', 1)
ON CONFLICT DO NOTHING;

-- Employees
INSERT INTO employees (first_name, last_name, department_id, company_id, hired_date, email, phone, job_title)
VALUES
    ('Alice', 'Roberts', (SELECT department_id FROM departments WHERE department_name='Finance'), 1, '2024-12-01', 'alice.roberts@superglobal.com', '555-1000', 'Senior Accountant'),
    ('Bob', 'Johnson', (SELECT department_id FROM departments WHERE department_name='Sales'), 1, '2024-11-10', 'bob.johnson@superglobal.com', '555-2000', 'Sales Executive'),
    ('Clara', 'Miller', (SELECT department_id FROM departments WHERE department_name='Operations'), 1, '2024-10-05', 'clara.miller@superglobal.com', '555-3000', 'Warehouse Supervisor')
ON CONFLICT DO NOTHING;

-- Pay Types
INSERT INTO pay_types (pay_type_name, default_rate_modifier)
VALUES
    ('Regular Hourly', 1),
    ('Overtime', 1.5),
    ('Double Overtime', 2),
    ('Bonus', 1)
ON CONFLICT DO NOTHING;

-- Pay Periods
INSERT INTO pay_periods (period_name, start_date, end_date)
VALUES
    ('Bi-Weekly #1 (2025)', '2025-01-01', '2025-01-14'),
    ('Bi-Weekly #2 (2025)', '2025-01-15', '2025-01-28')
ON CONFLICT DO NOTHING;

-- Sample marketing campaign
INSERT INTO marketing_campaigns (campaign_name, start_date, end_date, budget)
VALUES
    ('Global Launch Campaign', '2025-02-01', '2025-04-01', 500000)
ON CONFLICT DO NOTHING;

-- Sample lead
INSERT INTO leads (lead_name, email, lead_source, campaign_id)
SELECT 'MegaCorp Potential Deal', 'contact@megacorp.com', 'Cold Email', (SELECT campaign_id FROM marketing_campaigns WHERE campaign_name='Global Launch Campaign')
WHERE NOT EXISTS (SELECT 1 FROM leads WHERE lead_name='MegaCorp Potential Deal');

-- Vendors
INSERT INTO vendors (vendor_name, phone, email, company_id)
VALUES
    ('Premier Supplies Inc.', '555-9999', 'info@premiersupplies.com', 1)
ON CONFLICT DO NOTHING;

-- Items
INSERT INTO items (item_name, item_sku, item_type, cost, price, currency_id, company_id)
SELECT 'SuperWidget X', 'SWX-100', 'Inventory', 15.00, 30.00,
    (SELECT currency_id FROM currencies WHERE currency_code='USD'),
    1
WHERE NOT EXISTS (SELECT 1 FROM items WHERE item_name='SuperWidget X');

-- Approval workflow example
INSERT INTO approval_workflows (workflow_name, document_type, sequence_number, approval_role_id)
SELECT 'PO Approval - Step 1', 'PO', 1, (SELECT erp_role_id FROM erp_roles WHERE role_name='Accounting Manager')
WHERE NOT EXISTS (
    SELECT 1 FROM approval_workflows 
    WHERE workflow_name='PO Approval - Step 1'
      AND document_type='PO'
);

-- Done populating a wide variety of data in our extremely extensive schema

EOF

echo ""
echo "==========================================================================================================="
echo "✅  POSTGRESQL 16 CONTAINER '${CONTAINER_NAME}' IS RUNNING."
echo "✅  DATABASE '${POSTGRES_DB}' INITIALIZED ON HOST PORT ${HOST_PORT}."
echo "==========================================================================================================="
echo "You can connect locally with:"
echo "  psql -h 127.0.0.1 -p ${HOST_PORT} -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
echo ""
echo "An ultra-expansive, thoroughly detailed ERP schema has been created."
echo "It includes multi-company, multi-subsidiary, advanced ledger, payroll,"
echo "HR, projects, manufacturing, budgeting, approvals, logistics, CRM,"
echo "and numerous other modules for demonstration purposes."
echo ""
echo "Feel free to explore, modify, or extend this environment as needed!"
echo "Best wishes on your Extreme ERP adventure!"
