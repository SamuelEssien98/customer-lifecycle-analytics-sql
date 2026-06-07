# Customer Lifecycle Analytics Using SQL

## Project Overview

A digital financial services company wanted to better understand customer engagement, retention, and profitability across its savings and investment products.

Using SQL, I analyzed customer, transaction, savings, and investment data to answer four key business questions:

1. Which customers actively use multiple financial products?
2. How frequently do customers transact?
3. Which accounts show signs of inactivity?
4. Which customers generate the highest long-term value?

The analysis demonstrates how SQL can be used to transform transactional data into actionable business insights that support growth, retention, and customer value optimization.

## Dataset Overview

The dataset represents customer activity on a digital financial services platform and contains information on customer profiles, savings transactions, investment plans, and withdrawals.

### Tables Used

| Table | Description |
|---------|-------------|
| users_customuser | Customer demographic and account information |
| savings_savingsaccount | Savings deposit transactions |
| plans_plan | Savings and investment plan records |
| withdrawals_withdrawal | Withdrawal transactions |

### Key Fields

- owner_id – Unique customer identifier
- plan_id – Unique plan identifier
- transaction_date – Date of transaction
- confirmed_amount – Value of successful deposits
- amount_withdrawn – Value of withdrawals
- is_regular_savings – Indicates savings plans
- is_a_fund – Indicates investment plans

### Analysis Scope

The project focuses on four business areas:

- Product Adoption (Cross-Sell Analysis)
- Customer Engagement (Transaction Frequency)
- Customer Retention (Inactivity Monitoring)
- Customer Value (Customer Lifetime Value)
