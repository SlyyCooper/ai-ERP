# ai-ERP 🦊

A comprehensive Enterprise Resource Planning (ERP) system built with Python, PostgreSQL, and AI integration using the Tangent framework. This project demonstrates a modern approach to ERP systems by incorporating AI-powered agents for various business functions.

## Overview

ai-ERP is an ambitious project that combines traditional ERP functionality with modern AI capabilities. It features:

- Multi-company and multi-subsidiary support
- Comprehensive financial management
- AI-powered employee and accounting management
- Advanced database schema with 50+ tables and 120+ relations
- Integration with OpenAI's GPT-4o model through the Tangent framework

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Database Structure](#database-structure)
- [AI Agents](#ai-agents)
- [Contributing](#contributing)
- [License](#license)

## Features

### Core ERP Features
- Multi-company and subsidiary management
- Financial accounting with journal entries
- Employee management
- Inventory control
- Sales and purchase order processing
- Project management
- HR and Payroll
- CRM and Marketing
- Tax management
- Budgeting and planning
- Workflow and approvals
- Document management
- Audit logging

### AI Integration
- AI-powered employee management agent
- Intelligent accounting manager
- Natural language processing for database operations
- Context-aware responses and suggestions

### Technical Features
- PostgreSQL 16 database
- UUID support for external references
- Comprehensive audit trailing
- Multi-currency handling
- Advanced security with role-based access control
- RESTful API support
- Scalable architecture

## Architecture

The system is built with a modular architecture:

```
ai-ERP/
├── docs/
│   └── db_structure.md
├── employees/
│   ├── accounting_manager.py
│   └── employee_management_agent.py
├── erp_db.sh
├── README.md
└── [Additional configuration files]
```

### Key Components

1. **Database Layer**
   - PostgreSQL 16
   - 50+ tables with comprehensive relationships
   - Advanced data integrity features

2. **AI Layer (Tangent Framework)**
   - Integration with OpenAI's GPT-4o
   - Custom agents for specific business functions
   - Natural language processing capabilities

3. **Application Layer**
   - Python-based backend
   - Modular agent system
   - RESTful API endpoints

## Prerequisites

- Python 3.8+
- PostgreSQL 16
- Docker
- OpenAI API key
- Tangent Python library
- Additional Python packages:
  - psycopg2-binary
  - openai

## Installation

1. Clone the repository:
```bash
git clone https://github.com/SlyyCooper/ai-ERP.git
cd ai-ERP
```

2. Set up the PostgreSQL database:
```bash
chmod +x erp_db.sh
./erp_db.sh
```

3. Install required Python packages:
```bash
pip install tangent openai psycopg2-binary
```

4. Set up your environment variables:
```bash
export OPENAI_API_KEY="your-api-key"
export PGHOST="127.0.0.1"
export PGPORT="5433"
export PGDATABASE="extreme_erp_database"
export PGUSER="erp_user"
export PGPASSWORD="erp_pass"
```

## Usage

### Employee Management Agent

```bash
python employees/employee_management_agent.py
```

Example commands:
- Create: "Create an employee with first_name=John, last_name=Doe, department_id=2, company_id=1, email=john.doe@acme.com"
- Edit: "Edit employee with ID=7, set new_email to jdoe@somecompany.com"
- Delete: "Delete employee with ID=7"

### Accounting Manager

```bash
python employees/accounting_manager.py
```

Example commands:
- Create: "Create a journal entry with entry_date=2024-12-01, description='Opening balances', period_id=1, company_id=1"
- Edit: "Edit journal entry with ID=10 to set description to 'Adjusted opening balances'"
- Delete: "Delete journal entry with ID=5"

## Database Structure

The database is organized into multiple modules:

1. Global Configuration
2. User Management & Security
3. Financial Accounting
4. Sales & Receivables
5. Purchasing & Payables
6. Inventory Management
7. Human Resources & Payroll
8. Project Management
9. CRM & Marketing
10. Organizational Structure
11. Tax Management
12. Budgeting & Planning
13. Workflow & Approvals
14. System Integration & Audit

For detailed database documentation, see [docs/db_structure.md](docs/db_structure.md).

## AI Agents

### Employee Management Agent
- Handles employee CRUD operations
- Natural language interface
- Integrated with PostgreSQL database
- Uses GPT-4o model for understanding and processing requests

### Accounting Manager Agent
- Manages journal entries
- Processes accounting transactions
- Provides natural language interface for financial operations
- Integrated with the ERP database

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

SlyyCooper 🦊

## Acknowledgments

- OpenAI for GPT-4o model
- Tangent framework for AI integration
- PostgreSQL team for the robust database system

---

For more information or support, please open an issue in the GitHub repository.
