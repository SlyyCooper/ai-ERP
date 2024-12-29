# Comprehensive ERP Database Structure Documentation

## Overview
This document outlines the complete structure of our enterprise-grade ERP database system. The database is organized into multiple modules, each handling specific business functions.

## Modules Overview

### 1. Global Configuration
- **global_settings**: System-wide configuration parameters
- **companies**: Parent companies information
- **subsidiaries**: Subsidiary companies linked to parent companies
- **currencies**: Supported currencies
- **exchange_rates**: Currency exchange rates with different types

### 2. User Management & Security
- **erp_users**: System users
- **erp_roles**: User roles (e.g., Administrator, Accounting Manager)
- **erp_permissions**: Individual permissions
- **erp_user_roles**: User-role assignments
- **erp_role_permissions**: Role-permission assignments

### 3. Financial Accounting
- **chart_of_accounts**: Chart of accounts structure
- **chart_of_accounts_attributes**: Additional account attributes
- **fiscal_calendars**: Fiscal year definitions
- **fiscal_periods**: Individual periods within fiscal years
- **journal_entries**: General ledger entries
- **journal_line_items**: Individual lines within journal entries

### 4. Sales & Receivables
- **customers**: Customer master data
- **sales_orders**: Sales order headers
- **so_lines**: Sales order line items
- **invoices**: Customer invoices
- **invoice_lines**: Invoice line items

### 5. Purchasing & Payables
- **vendors**: Vendor master data
- **purchase_orders**: Purchase order headers
- **po_lines**: Purchase order line items
- **bills**: Vendor bills
- **bill_lines**: Bill line items

### 6. Inventory Management
- **items**: Product/service master data
- **inventory_transactions**: Stock movements
- **lot_serials**: Lot/Serial number tracking
- **lot_serial_transactions**: Lot/Serial movements
- **bill_of_materials**: Product components/recipes
- **manufacturing_orders**: Production orders

### 7. Human Resources & Payroll
- **employees**: Employee master data
- **employee_benefits**: Employee benefits information
- **pay_types**: Types of compensation
- **pay_periods**: Payroll periods
- **payroll_runs**: Payroll processing records
- **payroll_run_details**: Individual payroll calculations

### 8. Project Management
- **projects**: Project master data
- **project_tasks**: Project task breakdown
- **project_costs**: Project-related costs
- **timesheets**: Employee time tracking
- **time_entries**: Individual time entries

### 9. CRM & Marketing
- **leads**: Sales leads
- **marketing_campaigns**: Marketing campaign data
- **carriers**: Shipping carriers
- **shipments**: Shipment tracking

### 10. Organizational Structure
- **departments**: Department definitions
- **locations**: Location/facility information
- **classes**: Additional business segmentation

### 11. Tax Management
- **tax_jurisdictions**: Tax authority definitions
- **tax_codes**: Tax rates and rules

### 12. Budgeting & Planning
- **budgets**: Budget headers
- **budget_lines**: Budget line items
- **consolidations**: Financial consolidation data

### 13. Workflow & Approvals
- **approval_workflows**: Workflow definitions
- **approval_requests**: Approval tracking

### 14. System Integration & Audit
- **system_integrations**: External system connections
- **scheduled_jobs**: Automated task scheduling
- **audit_logs**: System audit trail
- **document_attachments**: File attachments

## Database Statistics
- Total Tables: 50+ (excluding sequences)
- Total Relations: 120+
- Schema Owner: erp_user
- Database Name: extreme_erp_database

## Key Features
1. Multi-company support
2. Multi-currency handling
3. Comprehensive audit trailing
4. Workflow management
5. Document management
6. Integrated CRM
7. Full supply chain management
8. Manufacturing support
9. Project management
10. HR and Payroll processing

## Technical Notes
- All tables use SERIAL PRIMARY KEYs
- UUID support for external references
- Timestamp tracking on all tables
- Proper foreign key constraints
- Calculated columns where appropriate
- JSONB support for flexible data storage

## Detailed Table Structures

### Companies Table (Core Table Example)
The companies table is a central table that many other tables reference. It stores information about legal entities in the system.

#### Columns:
- **company_id** (integer, PK): Auto-incrementing primary key
- **external_company_uuid** (uuid): Globally unique identifier, auto-generated
- **company_name** (varchar[255]): Company's business name (required)
- **company_legal_name** (varchar[255]): Official legal name
- **tax_id_number** (varchar[50]): Tax identification number
- **incorporation_country** (varchar[100]): Country of incorporation
- **base_currency_code** (varchar[10]): Default currency for the company
- **default_language** (varchar[10]): Default language code
- **address_line1** (varchar[255]): Primary address
- **address_line2** (varchar[255]): Secondary address
- **city** (varchar[100]): City
- **state_province** (varchar[100]): State or province
- **country** (varchar[100]): Country
- **postal_code** (varchar[50]): Postal/ZIP code
- **phone** (varchar[50]): Contact phone number
- **email** (varchar[100]): Contact email
- **created_at** (timestamp): Record creation timestamp
- **is_active** (boolean): Active status flag

#### Referenced By:
The companies table is referenced by many other tables, including:
1. chart_of_accounts
2. bills
3. budgets
4. fiscal_calendars
5. classes
6. consolidations
7. customers
8. departments
9. employees
10. erp_users
11. invoices
12. items
13. journal_entries
14. locations
15. purchase_orders
16. payroll_runs
17. projects
18. sales_orders
19. subsidiaries
20. vendors

This extensive referencing demonstrates the central role of the companies table in the ERP system's data model.

### Journal Entries Table (Financial Example)
The journal_entries table is a core financial table that stores all accounting entries in the system.

#### Columns:
- **journal_entry_id** (integer, PK): Auto-incrementing primary key
- **external_je_uuid** (uuid): Globally unique identifier for external reference
- **entry_date** (date): Date of the journal entry (required)
- **description** (text): Description of the transaction
- **period_id** (integer): Reference to fiscal period (required)
- **company_id** (integer): Reference to company (required)
- **subsidiary_id** (integer): Reference to subsidiary (optional)
- **posted** (boolean): Indicates if entry is posted to GL, defaults to false
- **created_at** (timestamp): Record creation timestamp

#### Relationships:
- Foreign Keys:
  - company_id → companies(company_id)
  - period_id → fiscal_periods(period_id)
  - subsidiary_id → subsidiaries(subsidiary_id)
- Referenced By:
  - journal_line_items: Contains the individual debit and credit lines

This table is central to the financial accounting module, storing all journal entries that affect the general ledger.

## Database Relationships Overview

The database implements a complex web of relationships that ensure data integrity and support business processes. Key relationship examples:

1. **Company Hierarchy**
   - Companies → Subsidiaries (one-to-many)
   - Companies → Departments (one-to-many)
   - Companies → Locations (one-to-many)

2. **Financial Structure**
   - Companies → Chart of Accounts (one-to-many)
   - Journal Entries → Journal Line Items (one-to-many)
   - Fiscal Calendars → Fiscal Periods (one-to-many)

3. **Business Transactions**
   - Sales Orders → SO Lines (one-to-many)
   - Purchase Orders → PO Lines (one-to-many)
   - Invoices → Invoice Lines (one-to-many)

4. **HR & Payroll**
   - Employees → Timesheets (one-to-many)
   - Payroll Runs → Payroll Run Details (one-to-many)
   - Employees → Employee Benefits (one-to-many)

## Data Integrity Features

1. **Primary Keys**
   - All tables have integer-based primary keys (SERIAL)
   - UUID fields for external reference

2. **Foreign Key Constraints**
   - Proper referential integrity
   - Cascading rules where appropriate

3. **Default Values**
   - Timestamps for audit trails
   - Status flags with sensible defaults
   - UUID generation for external references

4. **Data Validation**
   - NOT NULL constraints where required
   - Check constraints for valid values
   - Proper data type selection

## Performance Considerations

1. **Indexing**
   - Primary key indexes on all tables
   - Foreign key indexes
   - Additional indexes on frequently queried fields

2. **Data Types**
   - Appropriate size limitations on VARCHAR fields
   - Use of TEXT for unlimited string data
   - NUMERIC(15,2) for financial amounts
   - Proper date/time types

3. **Storage**
   - TOAST storage for large text fields
   - Compression options available
   - Proper column ordering
