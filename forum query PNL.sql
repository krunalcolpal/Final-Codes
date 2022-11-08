

{{ config(

    

  materialized='incremental',
    unique_key=['CALYEARMONTH', 'CURRENCY_FLAG','VALUE_TYPE','VERSION','COMP_CODE','PROFIT_CENTER','BUSINESS_SEGMENT','SUB_BRAND','MBCLUSTER','Material','Variant','CUST_HIER_LVL_1','CUST_HIER_LVL_2','CUST_HIER_LVL_3','CUST_HIER_LVL_4','CUST_HIER_LVL_5'],
    on_schema_change='sync_all_columns',
    incremental_strategy='delete+insert'

)}}
WITH BASE as  -------- selecting only required columns out of 600+ columns
(
SELECT ("Currency_Flag" || "Currency") as "Flag" ,

--#dimensions
--#Time
"Calendar Year", "Calendar Month", "Quarter", "Calendar Month/Year", "Calendar Year/Quarter",
--#Currency and Versions
"Currency_Flag", "Currency", "Value Type", "Version", 
--#company_code and region
"Company Code", "Division Description", "Reporting Division Description", 
"Country" as "COUNTRY_ABBR", "Region" as "REGION_ABBR", "Sales Organization",
"Region Description", "Country Description", "Subsidiary", "Subsidiary Description", 
--#Extras
"Business Segment - Profit Center", "Sales Office", "Geo Cluster", "Sales Office Description", "Geo Cluster Description",
--#product dimensions
"Category","Sub Category","Brand Equity","Sub Brand",
"Category Description" , "Sub Category Description", "Brand Equity Description", "Sub Brand Description","Material","Variant","Variant Description",
--#customer dimensions
"Customer","Cust Hier Lvl_1","Cust Hier Lvl_1_Description","Cust Hier Lvl_2" ,"Cust Hier Lvl_2_Description", 
"Cust Hier Lvl_3","Cust Hier Lvl_3_Description", "Cust Hier Lvl_4","Cust Hier Lvl_4_Description", 
"Cust Hier Lvl_5","Cust Hier Lvl_5_Description", "Retail Environment / Middleman" , "Retail Environment / Middleman Description",


--# metrics
"Tons",  "Pieces",  "Gross Sales (net)" ,  "Gross to Net" ,  "Net Sales",  "Variable Costs",  "Consumer Investment",  "Customer Investment",  "Margin",  "Non Variable Overhead",  "Operating Contribution",
"Total Advertising",  "Operating Profit",  "Division Reserves",  "Gross Profit",  "Media",  "Consumer Promotion",  "Cases",  "Special Pack / FG",  "Coupons",  "C&O - Reb/Pay",  "Permanent Price Reduction",
"Temporary Price Reduction",  "Every Day Low Price",  "Closeouts",  "Inventory Price Reduction",  "Prompt Payment",  "Efficiency Drivers",  "Business Builders Direct",  "Assortment",  "Customer Promotions",
"Growth Direct",  "New Product Incentive",  "Shoppers Marketing",  "Business Builders Indirect",  "Middleman Performance",  "Middleman Infrastructure",  "Growth Indirect",  "Indirect Retailer Investment",
"Other Customer Investment",  "Listing Allowances",  "Non Performance Trade Payment",  "Net Working Media",  "Net Production Cost",   "Other Media",  "Couponing Distrib. and Printing",  "Sampling",
"Contests - Prizes / Publicity",  "House to House Sell",  "Prof Relations",  "School Program",  "Display and Printed Matter(Total)",  "3rd Party Consumer Insights",  "Other Promotion - 3rd Party Payments",
"In-store Promotion - 3rd Party Payments",  "Future Advertising",  "Net Profit After Tax",  "Invoiced Sales",  "Variable Manufacturing Expenses",  "Purchase Finished Goods",  "Duties on Import FG",
"Variable Factory Costs",  "Packing Material",  "Raw Materials",  "Other VFC",  "Sourcing Expense",  "Conversion Labor",  "Conversion Expense",  "Other (Other VFC)",  "variable variances",  "PPV Variance",
"Loss & Gain Variance",  "Other Variable Variances",  "Co-Packing Costs",  "Variable Logistics Costs",  "Replenish. Freight Local",  "Replenishment Freight ICO",  "Warehousing Variable",  "Warehousing Variable ICO",
"Variable Warehouse Variance",  "Freight to Customers",  "Other (VLC)",  "OTHER VARIABLE TDC RELATED",  "Economic Margin Adjustment",  "Revaluation"    ,  "Contest & Offers - Premiums and On-packs",  "Other (Var. TDC)",
"Green Dot",  "OTHER VARIABLE NON TDC RELATED",  "Bad Debts",  "Sales Commissions",  "Other (Var non TDC)"

FROM "CROSS_FUNCTIONAL"."PNL_CURATED"."PNL_ACT_PLN_view"

WHERE "Version" IN ('','BNY','E03', 'E05','E09')  -- Selecting only required version
AND "Multi Pack Flag" IN ('', '3','0','8','9')   -- Given by business
AND "Inter Company Flag" IN ('', '3','0','8')  -- Given by business
),

---- Aggregating PNL data at dimensions
PNL as 

(
  SELECT

--dimensions
  "Calendar Year" as "YEAR",
  "Calendar Month" as "MONTH",
  "Quarter" as "QUARTER",
  "Calendar Month/Year" as "CALYEARMONTH", -- added for row level security
  "Calendar Year/Quarter" as "CALYEARQTR",

  "Currency_Flag" as "CURRENCY_FLAG",
  "Currency" as "CURRENCY",
  "Value Type" as "VALUE_TYPE",  -- added for row level security
  CASE
  WHEN "Version" = '' THEN 'Actual' 
  WHEN "Version" = 'BNY' THEN 'Budget'
  WHEN "Version" = 'E03' THEN 'Mar LE'
  WHEN "Version" = 'E05' THEN 'May LE'
  WHEN "Version" = 'E09' THEN 'Sep LE'
  ELSE "Version"
  END as "VERSION",
  "Company Code" as "COMP_CODE",

  "Division Description" as "DIVISION",
  "Reporting Division Description" as "REP_DIVISION",
  "REGION_ABBR",
  "Sales Organization",
  "Region Description" as "REGION",
  
  
  "COUNTRY_ABBR", -- ABV of country
  
  "Country Description" as "COUNTRY",
  "Subsidiary" as "CDC_ENT", -- added for row level security  -- Subsidiary
  "Subsidiary Description" as "SUBSIDIARY",
  "Business Segment - Profit Center" as "PROFIT_CENTER",
  CASE
  WHEN "Sales Office" = '' THEN 'NULL'
  ELSE "Sales Office"
  END as "Sales Office", 
  CASE
  WHEN "Geo Cluster" = '' THEN 'NULL'
  ELSE "Geo Cluster"
  END as "Geo Cluster", 
  "Sales Office Description",
  "Geo Cluster Description",
   
  "Category" as "CATEGORY",
  "Sub Category" as "SUB_CATEGORY",
  "Brand Equity" as "BRAND",
  "Sub Brand" as "SUB_BRAND",

  "Category Description" as "CATEGORY_DESC",
  "Sub Category Description" as "SUB_CATEGORY_DESC",
  "Brand Equity Description" as "BRAND_DESC",
  "Sub Brand Description" as "SUB_BRAND_DESC",
  "Material" ,
  "Variant",
  "Variant Description",
  "Customer" as "Customer",
  
  "Cust Hier Lvl_1" as "CUST_HIER_LVL_1",
  "Cust Hier Lvl_2" as "CUST_HIER_LVL_2",
  "Cust Hier Lvl_3" as "CUST_HIER_LVL_3",
  "Cust Hier Lvl_4" as "CUST_HIER_LVL_4",
  "Cust Hier Lvl_5" as "CUST_HIER_LVL_5",

  "Cust Hier Lvl_1_Description" as "CUST_HIER_LVL_1_DESC",
  "Cust Hier Lvl_2_Description" as "CUST_HIER_LVL_2_DESC",
  "Cust Hier Lvl_3_Description" as "CUST_HIER_LVL_3_DESC",
  "Cust Hier Lvl_4_Description" as "CUST_HIER_LVL_4_DESC",
  "Cust Hier Lvl_5_Description" as "CUST_HIER_LVL_5_DESC",
  "Retail Environment / Middleman",
  "Retail Environment / Middleman Description",

  --# metrics
  ZEROIFNULL(SUM("Tons")) as "TONS_TOTAL",
  ZEROIFNULL(SUM("Pieces")) as "PIECES_TOTAL",
  ZEROIFNULL(SUM("Gross Sales (net)")) as "GROSS_SALES(NET)",
  ZEROIFNULL(SUM("Gross to Net")) as "GROSS_TO_NET",
  ZEROIFNULL(SUM("Net Sales")) as "NET_SALES",
  ZEROIFNULL(SUM("Variable Costs")) as "VARIABLE_COST",
  ZEROIFNULL(SUM("Consumer Investment")) as "CONSUMER_INVESTMENT",
  ZEROIFNULL(SUM("Customer Investment")) as "CUSTOMER_INVESTMENT",
  ZEROIFNULL(SUM("Margin")) as "MARGIN",
  ZEROIFNULL(SUM("Non Variable Overhead")) as "TOTAL_NVOS",
  ZEROIFNULL(SUM("Operating Contribution")) as "OPERATING_CONTRIBUTION",
  ZEROIFNULL(SUM("Total Advertising")) as "TOTAL_ADVERTISING",
  ZEROIFNULL(SUM("Division Reserves")) as "DIF_RESERVES",
  ZEROIFNULL(SUM("Division Reserves")) as "Division Reserves",
  ZEROIFNULL(SUM("Operating Profit")) as "OPERATING_PROFIT",
  ZEROIFNULL(SUM("Gross Profit")) as "GROSS_PROFIT_MARGIN",
  ZEROIFNULL(SUM("Gross to Net")) + ZEROIFNULL(SUM("Media")) + ZEROIFNULL(SUM("Contest & Offers - Premiums and On-packs")) + ZEROIFNULL(SUM("Consumer Promotion")) as "COMMERCIAL_INVESTMENT",
  ZEROIFNULL(SUM("Media")) as "MEDIA",
  ZEROIFNULL(SUM("Consumer Promotion")) as "CONSUMER_PROMOTION",

  ZEROIFNULL(SUM("Cases")) as "CASES",
  ZEROIFNULL(SUM("Special Pack / FG")) as "SPECIAL_PACK_FG",
  ZEROIFNULL(SUM("Coupons")) as "COUPONS",
  ZEROIFNULL(SUM("C&O - Reb/Pay")) as "C&O - REB/PAY",
  ZEROIFNULL(SUM("Permanent Price Reduction")) as "PERMANENT_PRICE_REDUCTION",
  ZEROIFNULL(SUM("Temporary Price Reduction")) as "TEMPRARY_PRICE_REDUCTION",
  ZEROIFNULL(SUM("Every Day Low Price")) as "EVERY_DAY_LOW_PRICE",
  ZEROIFNULL(SUM("Closeouts")) as "CLOSEOUTS",
  ZEROIFNULL(SUM("Inventory Price Reduction")) as "INVENTORY_PRICE_REDUCTION",
  ZEROIFNULL(SUM("Prompt Payment")) as "PROMPT_PAYMENT",
  ZEROIFNULL(SUM("Efficiency Drivers")) as "EFFICIENCY_DRIVERS",
  ZEROIFNULL(SUM("Business Builders Direct")) as "BUSINESS_BUILDERS_DIRECT",
  ZEROIFNULL(SUM("Assortment")) as "ASSORTMENT",
  ZEROIFNULL(SUM("Customer Promotions")) as "CUSTOMER_PROMOTIONS",
  ZEROIFNULL(SUM("Growth Direct")) as "GROWTH_DIRECT",
  ZEROIFNULL(SUM("New Product Incentive")) as "NEW_PRODUCT_INCENTIVE",
  ZEROIFNULL(SUM("Shoppers Marketing")) as "SHOPPERS_MARKETING",
  ZEROIFNULL(SUM("Business Builders Indirect")) as "BUSINESS_BUILDERS_INDIRECT",
  ZEROIFNULL(SUM("Middleman Performance")) as "Middleman Performance",
  ZEROIFNULL(SUM("Middleman Infrastructure")) as "Middleman Infrastructure",
  ZEROIFNULL(SUM("Growth Indirect")) as "Growth Indirect",
  ZEROIFNULL(SUM("Indirect Retailer Investment")) as "Indirect Retailer Investment",
  ZEROIFNULL(SUM("Other Customer Investment")) as "Other Customer Investment",
  ZEROIFNULL(SUM("Listing Allowances")) as "Listing Allowances",
  ZEROIFNULL(SUM("Non Performance Trade Payment")) as "Non Performance Trade Payment",
  ZEROIFNULL(SUM("Net Working Media")) as "Net Working Media",
  ZEROIFNULL(SUM("Net Production Cost")) as "Net Production Cost",
  ZEROIFNULL(SUM("Other Media")) as "Other Media",
  ZEROIFNULL(SUM("Couponing Distrib. and Printing")) as "Couponing Distrib. and Printing",
  ZEROIFNULL(SUM("Sampling")) as "Sampling",
  ZEROIFNULL(SUM("Contests - Prizes / Publicity")) as "Contests - Prizes / Publicity",
  ZEROIFNULL(SUM("House to House Sell")) as "House to House Sell",
  ZEROIFNULL(SUM("Prof Relations")) as "Prof Relations",
  ZEROIFNULL(SUM("School Program")) as "School Program",
  ZEROIFNULL(SUM("Display and Printed Matter(Total)")) as "Display and Printed Matter(Total)",
  ZEROIFNULL(SUM("3rd Party Consumer Insights")) as "3rd Party Consumer Insights",
  ZEROIFNULL(SUM("Other Promotion - 3rd Party Payments")) as "Other Promotion - 3rd Party Payments",
  ZEROIFNULL(SUM("In-store Promotion - 3rd Party Payments")) as "In-store Promotion - 3rd Party Payments",
  ZEROIFNULL(SUM("Future Advertising")) as "Future Advertising",
  ZEROIFNULL(SUM("Operating Profit")) as "Operating Profit",
  ZEROIFNULL(SUM("Net Profit After Tax")) as "Net Profit After Tax",
  ZEROIFNULL(SUM("Gross Profit")) as "Gross Profit",
  ZEROIFNULL(SUM("Invoiced Sales")) as "Invoiced Sales",
  ZEROIFNULL(SUM("Variable Manufacturing Expenses")) as "Variable Manufacturing Expenses",
  ZEROIFNULL(SUM("Purchase Finished Goods")) as "Purchase Finished Goods",
  ZEROIFNULL(SUM("Duties on Import FG")) as "Duties on Import FG",
  ZEROIFNULL(SUM("Variable Factory Costs")) as "Variable Factory Costs",
  ZEROIFNULL(SUM("Packing Material")) as "Packing Material",
  ZEROIFNULL(SUM("Raw Materials")) as "Raw Materials",
  ZEROIFNULL(SUM("Other VFC")) as "Other VFC",
  ZEROIFNULL(SUM("Sourcing Expense")) as "Sourcing Expense",
  ZEROIFNULL(SUM("Conversion Labor")) as "Conversion Labor",
  ZEROIFNULL(SUM("Conversion Expense")) as "Conversion Expense",
  ZEROIFNULL(SUM("Other (Other VFC)")) as "Other (Other VFC)",
  ZEROIFNULL(SUM("variable variances")) as "variable variances",
  ZEROIFNULL(SUM("PPV Variance")) as "PPV Variance",
  ZEROIFNULL(SUM("Loss & Gain Variance")) as "Loss & Gain Variance",
  ZEROIFNULL(SUM("Other Variable Variances")) as "Other Variable Variances",
  ZEROIFNULL(SUM("Co-Packing Costs")) as "Co-Packing Costs",
  ZEROIFNULL(SUM("Variable Logistics Costs")) as "Variable Logistics Costs",
  ZEROIFNULL(SUM("Replenish. Freight Local")) as "Replenish. Freight Local",
  ZEROIFNULL(SUM("Replenishment Freight ICO")) as "Replenishment Freight ICO",
  ZEROIFNULL(SUM("Warehousing Variable")) as "Warehousing Variable",
  ZEROIFNULL(SUM("Warehousing Variable ICO")) as "Warehousing Variable ICO",
  ZEROIFNULL(SUM("Variable Warehouse Variance")) as "Variable Warehouse Variance",
  ZEROIFNULL(SUM("Freight to Customers")) as "Freight to Customers",
  ZEROIFNULL(SUM("Other (VLC)")) as "Other (VLC)",
  ZEROIFNULL(SUM("OTHER VARIABLE TDC RELATED")) as "OTHER VARIABLE TDC RELATED",
  ZEROIFNULL(SUM("Economic Margin Adjustment")) as "Economic Margin Adjustment",
  ZEROIFNULL(SUM("Revaluation")) as "Revaluation",
  ZEROIFNULL(SUM("Contest & Offers - Premiums and On-packs")) as "Contest & Offers - Premiums and On-packs",
  ZEROIFNULL(SUM("Other (Var. TDC)")) as "Other (Var. TDC)",
  ZEROIFNULL(SUM("Green Dot")) as "Green Dot",
  ZEROIFNULL(SUM("OTHER VARIABLE NON TDC RELATED")) as "OTHER VARIABLE NON TDC RELATED",
  ZEROIFNULL(SUM("Bad Debts")) as "Bad Debts",
  ZEROIFNULL(SUM("Sales Commissions")) as "Sales Commissions",
  ZEROIFNULL(SUM("Other (Var non TDC)")) as "Other (Var non TDC)"

--# tables
FROM BASE

--# conditions
WHERE
"Flag" != 'LCUSD' -- it was added due to HKE, HHR, CPA had USD as LC, and due to it # were doubled

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48

),

------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------BELOW STARTS SGA QUERY
------------------------------------------------------------------------------------------------------------------------------------------------
--- MBFIN table doesn't have dimensions in text so need to get that from master tables
TRANS as
(
SELECT

--# dimensions
"CALYEAR",
"CALQUART1" as "QUARTER",
"CALMONTH2" as "CALMONTH",
"CALMONTH" as "CALYEARMONTH",
"CALQUARTER" as "CALYEARQTR",

--#Currency and Versions
NULL as "CURRENCY_FLAG", ---- We need to bring this into MB Fin else business logic is required. As we are we doing union this column must have some value
"CURRENCY",
"VTYPE" as "VALUE_TYPE", --new added for row level security
"/BIC/MB_PVCP" as "VERSION",
--#company_code and region

"COMP_CODE",
"/BIC/CDC_ENT" as "CDC_ENT",
"/BIC/MBBUSSEG" as "BUSINESS_SEGMENT",

--#product dimensions
"/BIC/ZCATEGRY" as "CATEGORY",
"/BIC/ZSUBCATS" as "SUB_CATEGORY",
"/BIC/ZBREQTY" as "BRAND",
"/BIC/ZSUBBR" as "SUB_BRAND",
  
"/BIC/MBCLUSTER" as "MBCLUSTER", -- added new column for AFRICA division as SGA Base Volume was not showing correct value. On the request of Gisela 01-July-2022

--# metrics
SUM("/BIC/MBSGAVOL") as "BASE_VOLUME",
SUM("/BIC/MBSGAVOL") as "ALL_IN_VOLUME", -- need to write with formula including cluster, check formula
SUM("/BIC/MBSGAASP") as "SPI",
SUM("/BIC/MBSGAFX") as "FX",
SUM("/BIC/MBNS_CP") as "NET_SALES_CP",
SUM("/BIC/MBNS_PP") as "NET_SALES_PP",
SUM("VOL_ACQ") as "VOL_ACQ",
SUM("VOL_DIS") as "VOL_DIS",
SUM("SPI_DISPOSITION") as "SPI_DISPOSITION",
SUM("FX_DISPOSITION") as "FX_DISPOSITION",
SUM("/BIC/MBNSPI") as "NSPI",
SUM("/BIC/MBCONSPI") as "CON_SPI",
SUM("/BIC/MBCUSSPI") as "CUS_SPI"

--# tables
FROM
(
SELECT *,

(CASE WHEN "/BIC/MBCLUSTER" IN ('ACQUISITION') THEN "/BIC/MBSGAVOL" END) AS "VOL_ACQ", -- volume gain/loss due to acquisition
(CASE WHEN "/BIC/MBCLUSTER" IN ('DISPOSITION') THEN "/BIC/MBSGAVOL" END) AS "VOL_DIS", -- volume gain/loss due to disposition
(CASE WHEN "/BIC/MBCLUSTER" IN ('DISPOSITION') THEN ("/BIC/MBNSPI" + "/BIC/MBCONSPI" + "/BIC/MBCUSSPI") END) AS "SPI_DISPOSITION", -- SPI due to disposition
(CASE WHEN "/BIC/MBCLUSTER" IN ('DISPOSITION') THEN "/BIC/MBSGAFX" END) AS "FX_DISPOSITION"

FROM "PSA_PROD"."BI_BW_FI"."/BIC/AD_MB_FIN00" 


)

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17),

CATEGORY as
(SELECT DISTINCT "/BIC/ZCATEGRY" AS "CATEGORY", "/BIC/ZCATEGRY_DESC" as "CATEGORY_DESC" FROM "CROSS_FUNCTIONAL"."MASTERDATA"."MAT_SALES"),

SUB_CATEGORY as
(SELECT DISTINCT "/BIC/ZSUBCATS" as "SUB_CATEGORY", "/BIC/ZSUBCATS_DESC" AS "SUB_CATEGORY_DESC" FROM "CROSS_FUNCTIONAL"."MASTERDATA"."MAT_SALES"),

BRAND as
(SELECT DISTINCT "/BIC/ZBREQTY" as "BRAND", "/BIC/ZBREQTY_DESC" AS "BRAND_DESC" FROM "CROSS_FUNCTIONAL"."MASTERDATA"."MAT_SALES"),

SUB_BRAND as
(SELECT DISTINCT "/BIC/ZSUBBR" as "SUB_BRAND", "/BIC/ZSUBBR_DESC" AS "SUB_BRAND_DESC" FROM "CROSS_FUNCTIONAL"."MASTERDATA"."MAT_SALES"),


-- Main table
MAIN as
(SELECT

TRANS.*,

"COMP_CODE_DESC" as "COMP_CODE_DESC",
-- add hub here,
"/BIC/G_GDIVREP_DESC" as "DIVISION",
"/BIC/DIVREP_DESC" as "REP_DIVISION",
 
"COMPANY" as "REGION_ABBR",
"COMPANY_DESC" as "REGION",
 
country as "COUNTRY_ABBR",
"COUNTRY_DESC" as "COUNTRY",
"/BIC/CDC_ENT_DESC" as "SUBSIDIARY",

CATEGORY."CATEGORY_DESC",
SUB_CATEGORY."SUB_CATEGORY_DESC",
BRAND."BRAND_DESC",
SUB_BRAND."SUB_BRAND_DESC"

FROM TRANS
LEFT JOIN "CROSS_FUNCTIONAL"."MASTERDATA"."COMPANY_CODE" as CC ON TRANS."COMP_CODE" = CC."COMP_CODE"
LEFT JOIN CATEGORY ON TRANS."CATEGORY" = CATEGORY."CATEGORY"
LEFT JOIN SUB_CATEGORY ON TRANS."SUB_CATEGORY"  = SUB_CATEGORY."SUB_CATEGORY"
LEFT JOIN BRAND ON TRANS."BRAND" = BRAND."BRAND"
LEFT JOIN SUB_BRAND ON TRANS."SUB_BRAND" = SUB_BRAND."SUB_BRAND"
),


-- Main query
SGA as
(

SELECT

"CALYEAR" as "YEAR",
"CALMONTH" as "MONTH",
"QUARTER" as "QUARTER",
"CALYEARMONTH",
"CALYEARQTR",

"CURRENCY_FLAG",
"CURRENCY",
"VALUE_TYPE", -- added for row level security
CASE
WHEN "VERSION" = '' THEN 'Actual'
WHEN "VERSION" = 'BNY' THEN 'Budget'
WHEN "VERSION" = 'E03' THEN 'Mar LE'
WHEN "VERSION" = 'E05' THEN 'May LE'
WHEN "VERSION" = 'E09' THEN 'Sep LE'
ELSE "VERSION"
END as "VERSION",

"COMP_CODE",
"CDC_ENT", -- added for row level security
"BUSINESS_SEGMENT",
"DIVISION",
"REP_DIVISION",

"REGION_ABBR",
"REGION",
  
"COUNTRY_ABBR",  
"COUNTRY",
"SUBSIDIARY",

"CATEGORY" as "CATEGORY",
"SUB_CATEGORY" as "SUB_CATEGORY",
"BRAND" as "BRAND",
"SUB_BRAND" as "SUB_BRAND",

"CATEGORY_DESC" as "CATEGORY_DESC",
"SUB_CATEGORY_DESC" as "SUB_CATEGORY_DESC",
"BRAND_DESC" as "BRAND_DESC",
"SUB_BRAND_DESC" as "SUB_BRAND_DESC",
  
"MBCLUSTER",

ZEROIFNULL("BASE_VOLUME") as "BASE_VOLUME",
ZEROIFNULL("ALL_IN_VOLUME") as "ALL_IN_VOLUME",
ZEROIFNULL("SPI") as "SPI",
ZEROIFNULL("FX") as "FX",
ZEROIFNULL("NET_SALES_CP") as "NET_SALES_CP",
ZEROIFNULL("NET_SALES_PP") as "NET_SALES_PP",
ZEROIFNULL("VOL_ACQ") as "VOL_ACQ",
ZEROIFNULL("VOL_DIS") as "VOL_DIS",
ZEROIFNULL("SPI_DISPOSITION") as "SPI_DISPOSITION",
ZEROIFNULL("FX_DISPOSITION") as "FX_DISPOSITION",
ZEROIFNULL("NSPI") as "NSPI",
ZEROIFNULL("CON_SPI") as "CON_SPI",
ZEROIFNULL("CUS_SPI") as "CUS_SPI"

FROM MAIN

),
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--#MERGING PNL AND SGA DATA

MERGE_PNL_SGA as
(
SELECT
"YEAR", "MONTH", "QUARTER", "CALYEARMONTH","CALYEARQTR", "CURRENCY_FLAG", "CURRENCY", "VALUE_TYPE", "VERSION","COMP_CODE",
"CDC_ENT", "DIVISION","REP_DIVISION", "REGION_ABBR","Sales Organization", "REGION", "COUNTRY_ABBR", "COUNTRY","SUBSIDIARY","PROFIT_CENTER",
 NULL as "BUSINESS_SEGMENT", "Sales Office", "Geo Cluster", "Sales Office Description", "Geo Cluster Description",
COALESCE(Case when CATEGORY IN (NULL,'','NULL') then 'Other' else CATEGORY end,'Other') as "CATEGORY_DESC", 
NULL as "MBCLUSTER",
"SUB_CATEGORY_DESC", "BRAND_DESC","SUB_BRAND_DESC", 
"CATEGORY","SUB_CATEGORY","BRAND","SUB_BRAND","Material",
"Variant","Variant Description","Customer",
"CUST_HIER_LVL_1",  "CUST_HIER_LVL_2",  "CUST_HIER_LVL_3",  "CUST_HIER_LVL_4", "CUST_HIER_LVL_5",
"CUST_HIER_LVL_1_DESC","CUST_HIER_LVL_2_DESC","CUST_HIER_LVL_3_DESC","CUST_HIER_LVL_4_DESC","CUST_HIER_LVL_5_DESC",
"Retail Environment / Middleman","Retail Environment / Middleman Description",
0 as "BASE_VOLUME", 0 as "ALL_IN_VOLUME", 0 as "SPI", 0 as "FX", 0 as "NET_SALES_CP", 0 as "NET_SALES_PP", 
0 as "VOL_ACQ", 0 as "VOL_DIS", 0 as "SPI_DISPOSITION", 0 as "FX_DISPOSITION",0 as  "NSPI", 
0 as "CON_SPI", 0 as "CUS_SPI" ,"TONS_TOTAL","PIECES_TOTAL","GROSS_SALES(NET)","GROSS_TO_NET",
"NET_SALES","VARIABLE_COST","CONSUMER_INVESTMENT","CUSTOMER_INVESTMENT","MARGIN","TOTAL_NVOS",
"OPERATING_CONTRIBUTION","TOTAL_ADVERTISING","DIF_RESERVES","OPERATING_PROFIT","GROSS_PROFIT_MARGIN",
"COMMERCIAL_INVESTMENT","MEDIA","CONSUMER_PROMOTION",   "CASES",	"SPECIAL_PACK_FG",	"COUPONS",	"C&O - REB/PAY",	
"PERMANENT_PRICE_REDUCTION",	"TEMPRARY_PRICE_REDUCTION",	"EVERY_DAY_LOW_PRICE",	"CLOSEOUTS",	"INVENTORY_PRICE_REDUCTION",
"PROMPT_PAYMENT",	"EFFICIENCY_DRIVERS",	"BUSINESS_BUILDERS_DIRECT",	"ASSORTMENT",	"CUSTOMER_PROMOTIONS",	"GROWTH_DIRECT",
"NEW_PRODUCT_INCENTIVE",	"SHOPPERS_MARKETING",	"BUSINESS_BUILDERS_INDIRECT",	"Middleman Performance",	
"Middleman Infrastructure",	"Growth Indirect",	"Indirect Retailer Investment",	"Other Customer Investment",
"Listing Allowances",	"Non Performance Trade Payment",	"Net Working Media",	"Net Production Cost",
"Other Media",	"Couponing Distrib. and Printing",	"Sampling",	"Contests - Prizes / Publicity",
"House to House Sell",	"Prof Relations",	"School Program",	"Display and Printed Matter(Total)",	
"3rd Party Consumer Insights",	"Other Promotion - 3rd Party Payments",	"In-store Promotion - 3rd Party Payments",	
"Future Advertising",	"Division Reserves",	"Operating Profit",	"Net Profit After Tax",	"Gross Profit",	"Invoiced Sales",	
"Variable Manufacturing Expenses",	"Purchase Finished Goods",	"Duties on Import FG",	"Variable Factory Costs",	
"Packing Material",	"Raw Materials",	"Other VFC",	"Sourcing Expense",	"Conversion Labor",	"Conversion Expense",	
"Other (Other VFC)",	"variable variances",	"PPV Variance",	"Loss & Gain Variance",	"Other Variable Variances",	
"Co-Packing Costs",	"Variable Logistics Costs",	"Replenish. Freight Local",	"Replenishment Freight ICO",	
"Warehousing Variable",	"Warehousing Variable ICO",	"Variable Warehouse Variance",	"Freight to Customers",	"Other (VLC)",	
"OTHER VARIABLE TDC RELATED",	"Economic Margin Adjustment",	"Revaluation",	"Contest & Offers - Premiums and On-packs",	
"Other (Var. TDC)",	"Green Dot",	"OTHER VARIABLE NON TDC RELATED",	"Bad Debts",	"Sales Commissions",	"Other (Var non TDC)"
FROM PNL


UNION ALL


SELECT
"YEAR", "MONTH", "QUARTER", "CALYEARMONTH", "CALYEARQTR","CURRENCY_FLAG", "CURRENCY", "VALUE_TYPE", "VERSION","COMP_CODE","CDC_ENT", 
"DIVISION","REP_DIVISION","REGION_ABBR", "REGION", "COUNTRY_ABBR",NULL as "Sales Organization","COUNTRY","SUBSIDIARY", NULL as "PROFIT_CENTER", "BUSINESS_SEGMENT", NULL as "Sales Office", NULL as "Geo Cluster", NULL as "Sales Office Description", NULL as "Geo Cluster Description",
COALESCE(Case when CATEGORY IN (NULL,'','NULL') then 'Other' else CATEGORY end,'Other') as "CATEGORY_DESC", "MBCLUSTER",
"SUB_CATEGORY_DESC", "BRAND_DESC","SUB_BRAND_DESC","CATEGORY","SUB_CATEGORY","BRAND","SUB_BRAND", NULL as "Material",
NULL as "Variant",NULL as "Variant Description",NULL as "Customer",
NULL as "CUST_HIER_LVL_1", NULL as "CUST_HIER_LVL_2", NULL as "CUST_HIER_LVL_3", NULL as  "CUST_HIER_LVL_4", NULL as "CUST_HIER_LVL_5",
NULL as "CUST_HIER_LVL_1_DESC", NULL as "CUST_HIER_LVL_2_DESC", NULL as "CUST_HIER_LVL_3_DESC", 
NULL as  "CUST_HIER_LVL_4_DESC", NULL as "CUST_HIER_LVL_5_DESC",NULL as "Retail Environment / Middleman", NULL as "Retail Environment / Middleman Description",
"BASE_VOLUME","ALL_IN_VOLUME","SPI","FX","NET_SALES_CP",
"NET_SALES_PP","VOL_ACQ","VOL_DIS","SPI_DISPOSITION","FX_DISPOSITION","NSPI", 
"CON_SPI", "CUS_SPI" ,0 as "TONS_TOTAL", 0 as "PIECES_TOTAL", 0 as  "GROSS_SALES(NET)", 
0 as "GROSS_TO_NET", 0 as "NET_SALES", 0 as "VARIABLE_COST",0 as "CONSUMER_INVESTMENT",
0 as "CUSTOMER_INVESTMENT",0 as "MARGIN",0 as "TOTAL_NVOS",0 as "OPERATING_CONTRIBUTION",
0 as "TOTAL_ADVERTISING",0 as "DIF_RESERVES",0 as "OPERATING_PROFIT",0 as "GROSS_PROFIT_MARGIN",
0 as "COMMERCIAL_INVESTMENT",0 as "MEDIA",0 as "CONSUMER_PROMOTION", 0 as "CASES",	0 as "SPECIAL_PACK_FG",	
0 as "COUPONS",	0 as "C&O - REB/PAY",	0 as "PERMANENT_PRICE_REDUCTION",	0 as "TEMPRARY_PRICE_REDUCTION",	
0 as "EVERY_DAY_LOW_PRICE",	0 as "CLOSEOUTS",	0 as "INVENTORY_PRICE_REDUCTION",	0 as "PROMPT_PAYMENT",	
0 as "EFFICIENCY_DRIVERS",	0 as "BUSINESS_BUILDERS_DIRECT",	0 as "ASSORTMENT",	0 as "CUSTOMER_PROMOTIONS",	
0 as "GROWTH_DIRECT",	0 as "NEW_PRODUCT_INCENTIVE",	0 as "SHOPPERS_MARKETING",	0 as "BUSINESS_BUILDERS_INDIRECT",
0 as "Middleman Performance",	0 as "Middleman Infrastructure",	0 as "Growth Indirect",	0 as "Indirect Retailer Investment",	
0 as "Other Customer Investment",	0 as "Listing Allowances",	0 as "Non Performance Trade Payment",	0 as "Net Working Media",	
0 as "Net Production Cost",	0 as "Other Media",	0 as "Couponing Distrib. and Printing",	0 as "Sampling",	
0 as "Contests - Prizes / Publicity",	0 as "House to House Sell",	0 as "Prof Relations",	0 as "School Program",	
0 as "Display and Printed Matter(Total)",	0 as "3rd Party Consumer Insights",	0 as "Other Promotion - 3rd Party Payments",	
0 as "In-store Promotion - 3rd Party Payments",	0 as "Future Advertising",	0 as "Division Reserves",	0 as "Operating Profit",	
0 as "Net Profit After Tax",	0 as "Gross Profit",	0 as "Invoiced Sales",	0 as "Variable Manufacturing Expenses",	
0 as "Purchase Finished Goods",	0 as "Duties on Import FG",	0 as "Variable Factory Costs",	0 as "Packing Material",	
0 as "Raw Materials",	0 as "Other VFC",	0 as "Sourcing Expense",	0 as "Conversion Labor",	0 as "Conversion Expense",	
0 as "Other (Other VFC)",	0 as "variable variances",	0 as "PPV Variance",	0 as "Loss & Gain Variance",	
0 as "Other Variable Variances",	0 as "Co-Packing Costs",	0 as "Variable Logistics Costs",	
0 as "Replenish. Freight Local",	0 as "Replenishment Freight ICO",	0 as "Warehousing Variable",	
0 as "Warehousing Variable ICO",	0 as "Variable Warehouse Variance",	0 as "Freight to Customers",	
0 as "Other (VLC)",	0 as "OTHER VARIABLE TDC RELATED",	0 as "Economic Margin Adjustment",	0 as "Revaluation",	
0 as "Contest & Offers - Premiums and On-packs",	0 as "Other (Var. TDC)",	0 as "Green Dot",	
0 as "OTHER VARIABLE NON TDC RELATED",	0 as "Bad Debts",	0 as "Sales Commissions",	0 as "Other (Var non TDC)"
FROM SGA
)
SELECT *,
current_timestamp() as "INGESTION_TIME",
{% if is_incremental() %}
'incremental'
{% else %}
'full'
{% endif %} as "BUILD_SOURCE"
FROM MERGE_PNL_SGA 
Curated query.txt
Displaying Curated query.txt.
