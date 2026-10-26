## Building the Data Warehouse (Data Engineering)

### Objective
Develop a SQL Server warehouse that combines the supplied CRM and ERP CSV extracts for sales analysis.

### Specifications
- Clean source issues before analysis.
- Integrate CRM and ERP attributes into a model for customer, product, and sales reporting.
- Use the latest available product attributes; type 2 history is outside the current scope.
- Document the source-to-reporting flow and metric definitions.

## BI: Analytics & Reporting

The `analysis/` queries answer three starter questions:
- How do revenue, units, and distinct orders change month to month?
- Which products and categories contribute the most revenue and units?
- Which customers ordered more than once in the supplied period?

Order count means distinct order numbers because the fact is at order/product grain. A dashboard is a possible next step; the repository currently contains SQL analyses.
