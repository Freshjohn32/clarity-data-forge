# DataForge

[Previous content remains unchanged...]

## New Features

### Schema Versioning
Support for creating new versions of existing schemas while maintaining history:
```clarity
(contract-call? .data-forge create-schema-version
    schema-id
    (list "field1" "field2")
    (list "text" "number")
    (list true false))
```

### Batch Operations
Efficiently create multiple entries in a single transaction:
```clarity
(contract-call? .data-forge create-entries
    schema-id
    (list 
        (list "entry1-field1" "entry1-field2")
        (list "entry2-field1" "entry2-field2")))
```

### Query Support
Query entries by various criteria:
```clarity
(contract-call? .data-forge get-entries-by-owner
    schema-id
    owner-principal
    limit)
```

[Previous content continues...]
