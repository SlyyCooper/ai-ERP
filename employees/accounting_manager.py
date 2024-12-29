#!/usr/bin/env python3
#
# accounting_manager.py
#
# This script demonstrates how to use the Tangent library (with the `gpt-4o` model) to build
# an "Accounting Manager" agent that can connect to a PostgreSQL database (listening on port 5433)
# and perform create, edit, or delete operations on a hypothetical "journal_entries" table 
# in an ERP accounting system.
#
# Usage:
#   1) Ensure you have your Postgres DB up and running on port 5433 with a "journal_entries" table.
#   2) `pip install tangent openai psycopg2-binary`
#   3) Export your OpenAI API Key: `export OPENAI_API_KEY="sk-..."`
#   4) Run: `python accounting_manager.py`
#   5) Interact with the chatbot to create/edit/delete journal entries:
#       - "Create a journal entry with entry_date=2024-12-01, description='Opening balances', period_id=1, company_id=1"
#       - "Edit journal entry with ID=10 to set description to 'Adjusted opening balances'"
#       - "Delete journal entry with ID=5"
#

import os
import sys
import psycopg2
import openai

# Tangent imports (following the documentation)
from tangent import tangent, Agent, Response
from tangent.types import Result

###############################################################################
# 1. Set up OpenAI API key from environment
###############################################################################
openai.api_key = os.getenv("OPENAI_API_KEY", "")
if not openai.api_key:
    print("Please set the OPENAI_API_KEY environment variable.")
    sys.exit(1)

###############################################################################
# 2. Database functions for the "journal_entries" table
###############################################################################

def create_journal_entry(
    entry_date: str,
    description: str,
    period_id: int,
    company_id: int
) -> str:
    """
    Create a new journal entry in the 'journal_entries' table.
    Provide entry_date, description, period_id, company_id.
    Example usage:
      create_journal_entry(
        "2024-12-31",
        "Year-end adjustments",
        2,
        1
      )
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
        insert_sql = """
        INSERT INTO journal_entries (entry_date, description, period_id, company_id, posted, created_at)
        VALUES (%s, %s, %s, %s, FALSE, NOW())
        RETURNING journal_entry_id;
        """
        cur.execute(insert_sql, (entry_date, description, period_id, company_id))
        new_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return f"Journal entry created successfully! ID = {new_id}"
    except Exception as e:
        return f"Error creating journal entry: {e}"


def edit_journal_entry(journal_entry_id: int, new_description: str) -> str:
    """
    Update the description for an existing journal entry in 'journal_entries' table.
    Provide the ID of the journal entry and the new description text.
    Example usage:
      edit_journal_entry(10, "Revised opening balance notes")
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
        UPDATE journal_entries
           SET description = %s
         WHERE journal_entry_id = %s
        """
        cur.execute(update_sql, (new_description, journal_entry_id))
        rowcount = cur.rowcount
        conn.commit()
        cur.close()
        conn.close()
        if rowcount < 1:
            return f"No journal entry found with ID={journal_entry_id}"
        return f"Journal entry {journal_entry_id} updated successfully. New description: {new_description}"
    except Exception as e:
        return f"Error editing journal entry: {e}"


def delete_journal_entry(journal_entry_id: int) -> str:
    """
    Delete a journal entry record from 'journal_entries' table by ID.
    Example usage:
      delete_journal_entry(15)
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
        delete_sql = "DELETE FROM journal_entries WHERE journal_entry_id = %s"
        cur.execute(delete_sql, (journal_entry_id,))
        rowcount = cur.rowcount
        conn.commit()
        cur.close()
        conn.close()
        if rowcount < 1:
            return f"No journal entry found with ID={journal_entry_id}"
        return f"Journal entry with ID={journal_entry_id} deleted successfully."
    except Exception as e:
        return f"Error deleting journal entry: {e}"


###############################################################################
# 3. Define an Agent using Tangent
###############################################################################

# According to our "Veggie" style doc, we define an Agent that uses gpt-4o and references these DB functions.
accounting_manager_agent = Agent(
    name="Accounting Manager Agent",
    model="gpt-4o",
    instructions="""
You are an Accounting Manager who can create, edit, or delete journal entries
in the PostgreSQL database. The 'journal_entries' table has columns:
  - journal_entry_id
  - entry_date
  - description
  - period_id
  - company_id
  - posted
  - created_at
Use these 3 functions if the user explicitly requests create/edit/delete of a journal entry:
   1) create_journal_entry
   2) edit_journal_entry
   3) delete_journal_entry
Return friendly textual confirmations or clarifications if needed, 
but only call the function if user requests the action clearly.
""",
    functions=[create_journal_entry, edit_journal_entry, delete_journal_entry],
    parallel_tool_calls=False
)

###############################################################################
# 4. Run an Interactive Chat Loop
###############################################################################

def display_messages(msgs):
    for m in msgs:
        role = m.get("role", "")
        content = m.get("content", "")
        sender = m.get("sender", "")
        if role == "tool":
            print(f"[TOOL {m.get('tool_name','')}] => {content}")
        elif role == "assistant":
            print(f"Assistant: {content}")
        elif role == "user":
            print(f"User: {content}")


def main():
    print("====================================================================")
    print("  Tangent 'Accounting Manager' Chatbot - Postgres DB (Port 5433)   ")
    print("====================================================================")
    print("This system can create, edit, or delete 'journal_entries' in an ERP DB.")
    print("Example commands:\n")
    print('  "Create a journal entry with entry_date=2024-01-01, description=Opening, period_id=1, company_id=1"')
    print('  "Edit journal entry with ID=12 to set new_description to Reversed opening"')
    print('  "Delete journal entry with ID=15"')
    print("\nLeave empty line or press Ctrl+C to exit.\n")

    client = tangent()
    convo = []

    while True:
        user_input = input("User: ").strip()
        if not user_input:
            print("Exiting chat...")
            break

        # Add user message
        convo.append({"role": "user", "content": user_input})

        # Single turn run
        resp = client.run(
            agent=accounting_manager_agent,
            messages=convo,
            context_variables={},
            stream=False,
            debug=False,
            max_turns=1,
            execute_tools=True
        )

        # Append new messages
        new_msgs = resp.messages
        convo.extend(new_msgs)

        display_messages(new_msgs)


if __name__ == "__main__":
    main()
