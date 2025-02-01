# DataForge

DataForge is a decentralized platform for creating and managing data-driven applications on the Stacks blockchain. It provides core functionality for:

- Creating and managing data schemas with validation rules
- Storing and retrieving verified data entries
- Managing access control and permissions
- Supporting upgradeable data structures

## Features

- Schema Management: Define and update data schemas with field validation rules
- Data Validation: Built-in validation for common data types (email, number, date, URL)
- Data Verification: Support for verified data entries with designated verifiers
- Access Control: Granular permissions system including read, write, and verify rights
- Upgradeable: Support for schema versioning and updates

## Data Types
The following field types are supported with built-in validation:
- number: Validates numeric values
- date: Validates date values (as Unix timestamps)
- email: Validates email address format
- url: Validates URL format
- text: Free-form text without validation

## Getting Started

1. Install Clarinet
2. Clone this repository
3. Run `clarinet console` to interact with contracts
4. Run tests with `clarinet test`

## Usage

### Creating a Schema with Validation
```clarity
(contract-call? .data-forge create-schema
    "UserProfile"
    (list "email" "age" "website")
    (list "email" "number" "url")
    (list true true false))
```

### Creating a Validated Entry
```clarity
(contract-call? .data-forge create-entry
    schema-id
    (list "user@example.com" "25" "https://example.com"))
```

### Verifying an Entry
```clarity
(contract-call? .data-forge verify-entry schema-id entry-id)
```

See the contract documentation for detailed usage examples and API reference.
