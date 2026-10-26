## Project scope

Build a SQL Server warehouse from the supplied CRM and ERP CSV extracts. Clean and standardize the records before exposing a model for sales reporting.

## Data model

The sales fact uses the source order/product line grain. The current sample has no repeated order/product pairs, though it does not provide a separate line identifier. Dimensions cover customers, products, and dates. Gold uses the latest available product version for each product number; it does not preserve historical product attributes by sale date.

## Reporting questions

The SQL in `analysis/` provides starting points for:

- How are revenue, order count, and units changing month to month?
- Which products and categories contribute the most revenue and units?
- How often do customers purchase, and which customers are repeat buyers?

Order count means distinct order numbers, not the number of product rows. A packaged dashboard is outside the current repository scope.
