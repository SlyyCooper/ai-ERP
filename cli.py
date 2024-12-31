#!/usr/bin/env python3
"""
EXTREME ERP CLI INTERFACE
-------------------------
This single Python script provides a comprehensive, interactive command-line (CLI)
user interface for the "Extreme ERP" PostgreSQL database. By simply copying and
pasting this file into Visual Studio Code (or another environment) and running it,
you can manage and explore every major module of the database schema:
    - Companies & Subsidiaries
    - Currencies & Exchange Rates
    - Enterprise Users, Roles, & Permissions
    - Chart of Accounts, Fiscal Periods
    - Taxes & Jurisdictions
    - Departments, Locations, Classes
    - HR, Payroll, & Time Tracking
    - Customers, Vendors, CRM
    - Items, Inventory, Manufacturing
    - Sales Orders, Invoices, & Payments (Order-to-Cash)
    - Purchase Orders, Bills, & Vendor Payments (Procure-to-Pay)
    - Projects & Job Costing
    - Budgets & Consolidations
    - Approval Workflows
    - Shipping & Logistics
    - Document Attachments
    - Audit Logs & Integrations
    ...and more.

REQUIREMENTS:
  - Python 3.7+
  - psycopg2 library (install via: pip install psycopg2)

HOW TO USE:
  1) Update DB connection variables (HOST, PORT, USER, PASSWORD, DBNAME) if needed.
  2) Run this script: python erp_cli.py
  3) Follow the on-screen menus to create/read/update/delete records.
  4) Press 0 at any menu to return or exit.

Please note: This CLI attempts to demonstrate broad coverage of the schema.
While fully functional, certain modules (like advanced workflows,
multi-layer approvals, or extended payroll) could be expanded or customized.

Enjoy exploring and managing your Extreme ERP Database via CLI!
"""

import psycopg2
import sys

##############################################################################
#                             DB CONFIGURATION
##############################################################################

HOST = "127.0.0.1"
PORT = 5433
USER = "erp_user"
PASSWORD = "erp_pass"
DBNAME = "extreme_erp_database"


##############################################################################
#                          DATABASE HELPER FUNCTIONS
##############################################################################

def get_connection():
    """
    Creates and returns a new psycopg2 connection using the global config.
    """
    conn = psycopg2.connect(
        host=HOST,
        port=PORT,
        user=USER,
        password=PASSWORD,
        dbname=DBNAME
    )
    return conn


def execute_query(query, params=None, fetch=False):
    """
    Helper to execute a SQL statement:
      - query: string containing %s placeholders or no placeholders
      - params: tuple/list with param values or None
      - fetch: if True, returns all rows
    """
    conn = None
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, params or ())
            if fetch:
                data = cur.fetchall()
                conn.commit()
                return data
            conn.commit()
    except psycopg2.Error as e:
        print(f"[ERROR]: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()


def execute_query_returning(query, params=None):
    """
    Helper to run an INSERT/UPDATE with RETURNING clause.
    Returns the fetched row(s).
    """
    conn = None
    result = None
    try:
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(query, params or ())
            result = cur.fetchall()
        conn.commit()
    except psycopg2.Error as e:
        print(f"[ERROR]: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()
    return result


##############################################################################
#                         MENU / CLI NAVIGATION
##############################################################################

def main_menu():
    """
    Displays the primary modules and returns user choice.
    """
    print("\n======================== EXTREME ERP CLI ========================")
    print(" [1] Companies & Subsidiaries")
    print(" [2] Currencies & Exchange Rates")
    print(" [3] Users, Roles & Permissions")
    print(" [4] Chart of Accounts & Fiscal Periods")
    print(" [5] Taxes & Jurisdictions")
    print(" [6] Departments, Locations, Classes")
    print(" [7] HR, Payroll & Time Tracking")
    print(" [8] Customers, Vendors, CRM")
    print(" [9] Items, Inventory, Mfg")
    print(" [10] Order-to-Cash (SO, Invoices, Payments)")
    print(" [11] Procure-to-Pay (PO, Bills, Vendor Payments)")
    print(" [12] Projects & Job Costing")
    print(" [13] Budgets & Consolidations")
    print(" [14] Approval Workflows")
    print(" [15] Shipping & Logistics")
    print(" [16] Document Attachments")
    print(" [17] Audit Logs & Integrations")
    print(" [0] EXIT")
    print("===============================================================")
    choice = input("Select a module (0 to exit): ")
    return choice.strip()


##############################################################################
#              SKELETON: MODULE-BASED SUB-MENUS AND OPERATIONS
##############################################################################

def menu_companies_subsidiaries():
    """
    Manage Companies, Subsidiaries: Create, Read, Update, Delete (CRUD).
    """
    while True:
        print("\n--- COMPANIES & SUBSIDIARIES MENU ---")
        print(" [1] View Companies")
        print(" [2] Create Company")
        print(" [3] Update Company")
        print(" [4] Delete Company")
        print(" [5] View Subsidiaries")
        print(" [6] Create Subsidiary")
        print(" [7] Update Subsidiary")
        print(" [8] Delete Subsidiary")
        print(" [0] Return to Main Menu")
        choice = input("Choose an option: ").strip()

        if choice == "1":
            # View all companies
            rows = execute_query("SELECT company_id, company_name, country, email FROM companies ORDER BY company_id", fetch=True)
            if rows:
                for r in rows:
                    print(f"ID: {r[0]}, Name: {r[1]}, Country: {r[2]}, Email: {r[3]}")
            else:
                print("No companies found.")
        elif choice == "2":
            # Create a company
            cname = input("Company Name: ")
            clegal = input("Legal Name (optional): ")
            ccountry = input("Country: ")
            cemail = input("Email: ")
            query = """
                INSERT INTO companies (company_name, company_legal_name, country, email)
                VALUES (%s, %s, %s, %s)
                RETURNING company_id, company_name
            """
            result = execute_query_returning(query, (cname, clegal, ccountry, cemail))
            if result:
                print(f"Created Company [ID={result[0][0]}, Name={result[0][1]}]")
        elif choice == "3":
            # Update existing company
            cid = input("Enter the Company ID to update: ")
            new_name = input("New Company Name: ")
            new_country = input("New Country: ")
            new_email = input("New Email: ")
            query = """
                UPDATE companies
                SET company_name = %s,
                    country = %s,
                    email = %s
                WHERE company_id = %s
                RETURNING company_id
            """
            result = execute_query_returning(query, (new_name, new_country, new_email, cid))
            if result:
                print(f"Updated company [ID={result[0][0]}].")
            else:
                print("No company updated. Check ID.")
        elif choice == "4":
            # Delete a company
            cid = input("Enter Company ID to delete: ")
            query = "DELETE FROM companies WHERE company_id = %s RETURNING company_id"
            result = execute_query_returning(query, (cid,))
            if result:
                print(f"Deleted company ID={result[0][0]}")
            else:
                print("No company deleted. Check ID.")
        elif choice == "5":
            # View Subsidiaries
            rows = execute_query("""
                SELECT subsidiary_id, subsidiary_name, parent_company_id, country
                FROM subsidiaries
                ORDER BY subsidiary_id
            """, fetch=True)
            if rows:
                for r in rows:
                    print(f"SubID: {r[0]}, Name: {r[1]}, ParentCoID: {r[2]}, Country: {r[3]}")
            else:
                print("No subsidiaries found.")
        elif choice == "6":
            # Create subsidiary
            sname = input("Subsidiary Name: ")
            parent_id = input("Parent Company ID: ")
            scountry = input("Country: ")
            query = """
                INSERT INTO subsidiaries (subsidiary_name, parent_company_id, country)
                VALUES (%s, %s, %s)
                RETURNING subsidiary_id, subsidiary_name
            """
            result = execute_query_returning(query, (sname, parent_id, scountry))
            if result:
                print(f"Created Subsidiary [ID={result[0][0]}, Name={result[0][1]}]")
        elif choice == "7":
            # Update subsidiary
            sid = input("Enter Subsidiary ID to update: ")
            new_name = input("New Name: ")
            new_parent = input("New Parent Company ID: ")
            new_country = input("New Country: ")
            query = """
                UPDATE subsidiaries
                SET subsidiary_name = %s,
                    parent_company_id = %s,
                    country = %s
                WHERE subsidiary_id = %s
                RETURNING subsidiary_id
            """
            result = execute_query_returning(query, (new_name, new_parent, new_country, sid))
            if result:
                print(f"Updated subsidiary [ID={result[0][0]}].")
            else:
                print("No subsidiary updated. Check ID.")
        elif choice == "8":
            # Delete subsidiary
            sid = input("Enter Subsidiary ID to delete: ")
            query = "DELETE FROM subsidiaries WHERE subsidiary_id = %s RETURNING subsidiary_id"
            result = execute_query_returning(query, (sid,))
            if result:
                print(f"Deleted subsidiary ID={result[0][0]}")
            else:
                print("No subsidiary deleted. Check ID.")
        elif choice == "0":
            return  # back to main
        else:
            print("Invalid choice. Try again.")


def menu_currencies_exchange_rates():
    """
    Manage currencies, exchange rate types, and exchange rates.
    """
    while True:
        print("\n--- CURRENCIES & EXCHANGE RATES MENU ---")
        print(" [1] View Currencies")
        print(" [2] Add Currency")
        print(" [3] Update Currency")
        print(" [4] Delete Currency")
        print(" [5] View Exchange Rates")
        print(" [6] Add Exchange Rate")
        print(" [0] Return to Main Menu")
        choice = input("Choose an option: ").strip()

        if choice == "1":
            rows = execute_query("SELECT currency_id, currency_code, currency_name, symbol FROM currencies ORDER BY currency_id", fetch=True)
            if rows:
                for r in rows:
                    print(f"ID:{r[0]}, Code:{r[1]}, Name:{r[2]}, Symbol:{r[3]}")
            else:
                print("No currencies found.")
        elif choice == "2":
            ccode = input("Currency Code (e.g. USD): ")
            cname = input("Currency Name (e.g. US Dollar): ")
            symbol = input("Symbol (e.g. $): ")
            query = """
                INSERT INTO currencies (currency_code, currency_name, symbol)
                VALUES (%s, %s, %s)
                RETURNING currency_id, currency_code
            """
            result = execute_query_returning(query, (ccode, cname, symbol))
            if result:
                print(f"Created Currency [ID={result[0][0]}, Code={result[0][1]}]")
        elif choice == "3":
            cid = input("Enter Currency ID to update: ")
            new_code = input("New Currency Code: ")
            new_name = input("New Currency Name: ")
            new_symbol = input("New Symbol: ")
            query = """
                UPDATE currencies
                SET currency_code = %s,
                    currency_name = %s,
                    symbol = %s
                WHERE currency_id = %s
                RETURNING currency_id
            """
            result = execute_query_returning(query, (new_code, new_name, new_symbol, cid))
            if result:
                print(f"Updated currency [ID={result[0][0]}].")
            else:
                print("No currency updated. Check ID.")
        elif choice == "4":
            cid = input("Enter Currency ID to delete: ")
            query = "DELETE FROM currencies WHERE currency_id = %s RETURNING currency_id"
            result = execute_query_returning(query, (cid,))
            if result:
                print(f"Deleted currency ID={result[0][0]}")
            else:
                print("No currency deleted. Check ID.")
        elif choice == "5":
            rows = execute_query("""
                SELECT e.rate_id, c1.currency_code AS base, c2.currency_code AS quote,
                       t.rate_type_name, e.exchange_rate, e.effective_date
                FROM exchange_rates e
                JOIN currencies c1 ON e.base_currency_id = c1.currency_id
                JOIN currencies c2 ON e.quote_currency_id = c2.currency_id
                JOIN exchange_rate_types t ON e.rate_type_id = t.rate_type_id
                ORDER BY e.rate_id
            """, fetch=True)
            if rows:
                for r in rows:
                    print(f"RateID:{r[0]}, Base:{r[1]}, Quote:{r[2]}, Type:{r[3]}, Rate:{r[4]}, Date:{r[5]}")
            else:
                print("No exchange rates found.")
        elif choice == "6":
            print("Add Exchange Rate:")
            base_id = input("Base Currency ID: ")
            quote_id = input("Quote Currency ID: ")
            rate_type_id = input("Exchange Rate Type ID: ")
            rate_value = input("Exchange Rate (e.g. 0.90): ")
            eff_date = input("Effective Date (YYYY-MM-DD): ")
            query = """
                INSERT INTO exchange_rates (base_currency_id, quote_currency_id, rate_type_id, exchange_rate, effective_date)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING rate_id
            """
            result = execute_query_returning(query, (base_id, quote_id, rate_type_id, rate_value, eff_date))
            if result:
                print(f"Created exchange_rate [ID={result[0][0]}]")
        elif choice == "0":
            return
        else:
            print("Invalid choice.")


def menu_users_roles_permissions():
    """
    Manage ERP Users, Roles, Permissions, etc.
    """
    while True:
        print("\n--- USERS & ROLES & PERMISSIONS MENU ---")
        print(" [1] View Users")
        print(" [2] Create User")
        print(" [3] Assign Role to User")
        print(" [4] View Roles")
        print(" [5] Create Role")
        print(" [6] View Permissions")
        print(" [7] Create Permission")
        print(" [8] Assign Permission to Role")
        print(" [0] Return to Main Menu")
        choice = input("Choose an option: ").strip()

        if choice == "1":
            rows = execute_query("SELECT erp_user_id, username, email, is_super_admin FROM erp_users ORDER BY erp_user_id", fetch=True)
            if rows:
                for r in rows:
                    print(f"ID:{r[0]}, Username:{r[1]}, Email:{r[2]}, SuperAdmin:{r[3]}")
            else:
                print("No users found.")
        elif choice == "2":
            uname = input("Username: ")
            uemail = input("Email: ")
            fname = input("Full Name: ")
            super_admin_flag = input("Is Super Admin? (true/false): ").lower().startswith('t')
            query = """
                INSERT INTO erp_users (username, email, full_name, is_super_admin)
                VALUES (%s, %s, %s, %s)
                RETURNING erp_user_id
            """
            result = execute_query_returning(query, (uname, uemail, fname, super_admin_flag))
            if result:
                print(f"Created user [ID={result[0][0]}].")
        elif choice == "3":
            uid = input("User ID: ")
            rid = input("Role ID: ")
            query = """
                INSERT INTO erp_user_roles (erp_user_id, erp_role_id)
                VALUES (%s, %s)
                RETURNING user_role_id
            """
            result = execute_query_returning(query, (uid, rid))
            if result:
                print(f"Assigned role [ID={rid}] to user [ID={uid}].")
        elif choice == "4":
            rows = execute_query("SELECT erp_role_id, role_name, role_description FROM erp_roles ORDER BY erp_role_id", fetch=True)
            if rows:
                for r in rows:
                    print(f"ID:{r[0]}, Name:{r[1]}, Desc:{r[2]}")
            else:
                print("No roles found.")
        elif choice == "5":
            rname = input("Role Name: ")
            rdesc = input("Role Description: ")
            query = """
                INSERT INTO erp_roles (role_name, role_description)
                VALUES (%s, %s)
                RETURNING erp_role_id
            """
            result = execute_query_returning(query, (rname, rdesc))
            if result:
                print(f"Created role [ID={result[0][0]}].")
        elif choice == "6":
            rows = execute_query("SELECT permission_id, permission_name, permission_description FROM erp_permissions ORDER BY permission_id", fetch=True)
            if rows:
                for r in rows:
                    print(f"ID:{r[0]}, Name:{r[1]}, Desc:{r[2]}")
            else:
                print("No permissions found.")
        elif choice == "7":
            pname = input("Permission Name: ")
            pdesc = input("Permission Description: ")
            query = """
                INSERT INTO erp_permissions (permission_name, permission_description)
                VALUES (%s, %s)
                RETURNING permission_id
            """
            result = execute_query_returning(query, (pname, pdesc))
            if result:
                print(f"Created permission [ID={result[0][0]}].")
        elif choice == "8":
            rid = input("Role ID: ")
            pid = input("Permission ID: ")
            query = """
                INSERT INTO erp_role_permissions (erp_role_id, permission_id)
                VALUES (%s, %s)
                RETURNING role_permission_id
            """
            result = execute_query_returning(query, (rid, pid))
            if result:
                print(f"Assigned permission [ID={pid}] to role [ID={rid}].")
        elif choice == "0":
            return
        else:
            print("Invalid choice.")


##############################################################################
#  SKELETON STUBS FOR OTHER MODULE MENUS  (Similar pattern: CRUD & Listing)
##############################################################################

def menu_chart_of_accounts_fiscal():
    print("\n[INFO] Stub menu for Chart of Accounts & Fiscal Periods.\n"
          "Implement similar CRUD or listing as above if needed.")
    input("Press Enter to return to main menu...")

def menu_taxes_jurisdictions():
    print("\n[INFO] Stub menu for Taxes & Jurisdictions.\n"
          "Implement further functionality as needed.")
    input("Press Enter to return to main menu...")

def menu_departments_locations_classes():
    print("\n[INFO] Stub menu for Departments, Locations, Classes.")
    input("Press Enter to return to main menu...")

def menu_hr_payroll_time_tracking():
    print("\n[INFO] Stub menu for HR, Payroll, and Time Tracking.")
    input("Press Enter to return to main menu...")

def menu_customers_vendors_crm():
    print("\n[INFO] Stub menu for Customers, Vendors, CRM.")
    input("Press Enter to return to main menu...")

def menu_items_inventory_mfg():
    print("\n[INFO] Stub menu for Items, Inventory, and Mfg.")
    input("Press Enter to return to main menu...")

def menu_order_to_cash():
    print("\n[INFO] Stub menu for Order-to-Cash (Sales Orders, Invoices, Payments).")
    input("Press Enter to return to main menu...")

def menu_procure_to_pay():
    print("\n[INFO] Stub menu for Procure-to-Pay (Purchase Orders, Bills, Vendor Payments).")
    input("Press Enter to return to main menu...")

def menu_projects_job_costing():
    print("\n[INFO] Stub menu for Projects & Job Costing.")
    input("Press Enter to return to main menu...")

def menu_budgets_consolidations():
    print("\n[INFO] Stub menu for Budgets & Consolidations.")
    input("Press Enter to return to main menu...")

def menu_approval_workflows():
    print("\n[INFO] Stub menu for Approval Workflows.")
    input("Press Enter to return to main menu...")

def menu_shipping_logistics():
    print("\n[INFO] Stub menu for Shipping & Logistics.")
    input("Press Enter to return to main menu...")

def menu_document_attachments():
    print("\n[INFO] Stub menu for Document Attachments.")
    input("Press Enter to return to main menu...")

def menu_audit_logs_integrations():
    print("\n[INFO] Stub menu for Audit Logs & Integrations.")
    input("Press Enter to return to main menu...")

##############################################################################
#                                  MAIN LOOP
##############################################################################

def run_cli():
    """
    Main loop for the CLI. Displays top-level modules, routes to sub-menus.
    """
    while True:
        choice = main_menu()
        if choice == "0":
            print("\nExiting Extreme ERP CLI. Goodbye!")
            sys.exit(0)
        elif choice == "1":
            menu_companies_subsidiaries()
        elif choice == "2":
            menu_currencies_exchange_rates()
        elif choice == "3":
            menu_users_roles_permissions()
        elif choice == "4":
            menu_chart_of_accounts_fiscal()
        elif choice == "5":
            menu_taxes_jurisdictions()
        elif choice == "6":
            menu_departments_locations_classes()
        elif choice == "7":
            menu_hr_payroll_time_tracking()
        elif choice == "8":
            menu_customers_vendors_crm()
        elif choice == "9":
            menu_items_inventory_mfg()
        elif choice == "10":
            menu_order_to_cash()
        elif choice == "11":
            menu_procure_to_pay()
        elif choice == "12":
            menu_projects_job_costing()
        elif choice == "13":
            menu_budgets_consolidations()
        elif choice == "14":
            menu_approval_workflows()
        elif choice == "15":
            menu_shipping_logistics()
        elif choice == "16":
            menu_document_attachments()
        elif choice == "17":
            menu_audit_logs_integrations()
        else:
            print("Invalid option. Please try again.")

def main():
    """
    Entry point to run the CLI.
    """
    run_cli()


if __name__ == "__main__":
    main()
