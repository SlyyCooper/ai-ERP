#!/usr/bin/env python3
#
# employee_management_agent.py
#
# MONO-SCRIPT DEMO:
# This script provides a self-contained, functional chatbot using the Tangent framework with 
# multi-turn conversation and database connectivity to a PostgreSQL ERP database. 
# The script:
#   - Instantiates a Tangent client that uses the gpt-4o model
#   - Defines three Python functions (create_employee, edit_employee, delete_employee) 
#     for inserting, updating, and deleting records in a PostgreSQL table named 'employees'
#     from an ERP schema
#   - Sets up an Agent that references these functions as "tools"
#   - Runs a while-loop to continuously read user messages and get a response from the 
#     Tangent chatbot until the user leaves an empty line or Ctrl+C

"""
Mono-Script Tangent Chatbot with Postgres Integration
Usage:
  1) Make sure you have your Postgres DB running with the 'employees' table 
     from your "comprehensive_erp_db_setup_extreme.sh" script. 
  2) pip install tangent openai psycopg2-binary
  3) export OPENAI_API_KEY="sk-...."
  4) python employee_management_agent.py
  5) Start typing commands:
     - "Create an employee with first_name=John, last_name=Doe, department_id=2, company_id=1, email=john.doe@acme.com"
     - "Edit employee with ID=7, set new_email to jdoe@somecompany.com"
     - "Delete employee with ID=7"
"""

import os
import sys
import psycopg2
import openai
from tangent import tangent, Agent, Response
from tangent.types import Result


#############################
# 1. SET OPENAI API KEY
#############################
openai.api_key = os.getenv("OPENAI_API_KEY", "")
if not openai.api_key:
    print("Please set the OPENAI_API_KEY environment variable.")
    sys.exit(1)


#############################
# 2. DEFINE DATABASE FUNCTIONS
#############################

def create_employee(
    first_name: str,
    last_name: str,
    department_id: int,
    company_id: int,
    email: str
) -> str:
    """
    Create a new employee record in the 'employees' table, 
    with columns first_name, last_name, department_id, company_id, email, hired_date, is_active.
    Example usage: create_employee("Jane", "Doe", 1, 1, "jane.doe@mycompany.com")
    """
    # Connect to Postgres
    try:
        conn = psycopg2.connect(
            host=os.getenv("PGHOST", "127.0.0.1"),
            port=int(os.getenv("PGPORT", "5433")),
            database=os.getenv("PGDATABASE", "extreme_erp_database"),
            user=os.getenv("PGUSER", "erp_user"),
            password=os.getenv("PGPASSWORD", "erp_pass"),
        )
        cur = conn.cursor()
        insert_sql = """
            INSERT INTO employees (first_name, last_name, department_id, company_id, email, hired_date, is_active)
            VALUES (%s, %s, %s, %s, %s, NOW(), TRUE)
            RETURNING employee_id;
        """
        cur.execute(insert_sql, (first_name, last_name, department_id, company_id, email))
        new_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return f"Employee created successfully! Employee ID: {new_id}"
    except Exception as e:
        return f"Error creating employee: {e}"


def edit_employee(employee_id: int, new_email: str) -> str:
    """
    Edit an existing employee, updating the email address for the employee with given ID.
    Example usage: edit_employee(7, "new.email@example.com")
    """
    try:
        conn = psycopg2.connect(
            host=os.getenv("PGHOST", "127.0.0.1"),
            port=int(os.getenv("PGPORT", "5433")),
            database=os.getenv("PGDATABASE", "extreme_erp_database"),
            user=os.getenv("PGUSER", "erp_user"),
            password=os.getenv("PGPASSWORD", "erp_pass"),
        )
        cur = conn.cursor()
        update_sql = """
            UPDATE employees
               SET email = %s
             WHERE employee_id = %s
        """
        cur.execute(update_sql, (new_email, employee_id))
        rowcount = cur.rowcount
        conn.commit()
        cur.close()
        conn.close()
        if rowcount < 1:
            return f"No employee found with ID={employee_id}."
        return f"Employee with ID={employee_id} updated successfully. New email: {new_email}"
    except Exception as e:
        return f"Error updating employee: {e}"


def delete_employee(employee_id: int) -> str:
    """
    Delete an employee record by ID from the 'employees' table.
    Example usage: delete_employee(7)
    """
    try:
        conn = psycopg2.connect(
            host=os.getenv("PGHOST", "127.0.0.1"),
            port=int(os.getenv("PGPORT", "5433")),
            database=os.getenv("PGDATABASE", "extreme_erp_database"),
            user=os.getenv("PGUSER", "erp_user"),
            password=os.getenv("PGPASSWORD", "erp_pass"),
        )
        cur = conn.cursor()
        delete_sql = "DELETE FROM employees WHERE employee_id = %s"
        cur.execute(delete_sql, (employee_id,))
        rowcount = cur.rowcount
        conn.commit()
        cur.close()
        conn.close()
        if rowcount < 1:
            return f"No employee found with ID={employee_id} to delete."
        return f"Employee with ID={employee_id} successfully deleted."
    except Exception as e:
        return f"Error deleting employee: {e}"


#############################
# 3. CREATE TANGENT AGENT
#############################

my_agent = Agent(
    name="ERP-DB-Agent",
    model="gpt-4o",  # December 2024 new model
    instructions="""
You are an ERP Database Assistant that can create, edit, or delete employees
in the company's PostgreSQL database. You have three functions:
  - create_employee
  - edit_employee
  - delete_employee
Use these functions ONLY when the user clearly requests to create, edit, or delete an employee.
Always confirm you have the correct parameters (employee_id, email, etc.) before calling the function.
If the user wants to do something else, respond politely in text without calling a function.
""",
    functions=[create_employee, edit_employee, delete_employee],
    parallel_tool_calls=True
)

#############################
# 4. RUN A SIMPLE CHAT LOOP
#############################

def pretty_print(messages):
    for m in messages:
        role = m.get("role", "")
        sender = m.get("sender", "")
        content = m.get("content", "")
        if role == "tool":
            # tool calls output
            print(f"[TOOL {m.get('tool_name', '')}] => {content}")
        elif role == "assistant":
            print(f"Assistant: {content}")
        elif role == "user":
            print(f"User: {content}")


def main():
    print("============================================================")
    print("  Tangent Chatbot - PostgreSQL ERP Integration (GPT-4o)   ")
    print("============================================================\n")
    print("This AI can create, edit, or delete employees in the 'employees' table.")
    print("Ask it to do so, for example:")
    print('   "Create an employee with first_name=Jane, last_name=Doe, department_id=2, company_id=1, email=jane@example.com"')
    print('   "Edit employee with ID=10, set new_email to janeDoe99@example.net"')
    print('   "Delete employee with ID=10"')
    print("Press Ctrl+C or leave input blank to exit.\n")

    client = tangent()
    history = []

    while True:
        user_input = input("User: ").strip()
        if not user_input:
            print("No input. Exiting.")
            break

        # Add user's message
        history.append({"role": "user", "content": user_input})
        # Run one turn of conversation
        response = client.run(
            agent=my_agent,
            messages=history,
            context_variables={},
            stream=False,
            debug=False,
            max_turns=1,
            execute_tools=True
        )

        # The newly generated messages from the assistant (including any tool calls) are in response.messages
        new_messages = response.messages
        # Append them to conversation history
        history.extend(new_messages)

        # Print them
        pretty_print(new_messages)


if __name__ == "__main__":
    main()
