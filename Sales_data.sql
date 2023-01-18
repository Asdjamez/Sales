--Inspecting Data
select * from Projects..sales_data_sample

--Checking Unique Values
select  distinct STATUS from projects..sales_data_sample
select  distinct YEAR_ID from projects..sales_data_sample
select  distinct PRODUCTLINE from projects..sales_data_sample
select  distinct COUNTRY from projects..sales_data_sample
select  distinct DEALSIZE from projects..sales_data_sample
select  distinct TERRITORY from projects..sales_data_sample

--Checking Months in year for sales
select  DISTINCT MONTH_ID from projects..sales_data_sample where YEAR_ID = 2003 order by 1 asc
select  DISTINCT MONTH_ID from projects..sales_data_sample where YEAR_ID = 2004 order by 1 asc
select  DISTINCT MONTH_ID from projects..sales_data_sample where YEAR_ID = 2005 order by 1 asc


--Analysis
--Grouping Sales

select PRODUCTLINE, sum(sales) as Revenue
from Projects..sales_data_sample
group by PRODUCTLINE
order by 2 DESC

select YEAR_ID, sum(sales) as Revenue
from Projects..sales_data_sample
group by YEAR_ID
order by 2 DESC

select DEALSIZE, sum(sales) as Revenue
from Projects..sales_data_sample
group by DEALSIZE
order by 2 DESC


--Best month for sales in a specific year and how much was earned that month?

select MONTH_ID, sum(sales) as Revenue, Count(ordernumber) as Frequency
from Projects..sales_data_sample
where YEAR_ID = 2003
Group by MONTH_ID
order by 2 DESC

select MONTH_ID, sum(sales) as Revenue, Count(ordernumber) as Frequency
from Projects..sales_data_sample
where YEAR_ID = 2004
Group by MONTH_ID
order by 2 DESC

select MONTH_ID, sum(sales) as Revenue, Count(ordernumber) as Frequency
from Projects..sales_data_sample
where YEAR_ID = 2005
Group by MONTH_ID
order by 2 DESC

--its seems to be November is the  profitable month by sales

select MONTH_ID,PRODUCTLINE, sum(sales) as Revenue, Count(ordernumber) as Frequency
from Projects..sales_data_sample
where YEAR_ID = 2003 and MONTH_ID = 11 --Change year to check for 2004
Group by MONTH_ID, PRODUCTLINE
order by 3 DESC


--Identify best customer by RFM analysis

DROP TABLE IF EXISTS #rfm;
with rfm as
( 
  Select
      CUSTOMERNAME,
      sum(sales) Monetary_Value,
      avg(sales) Avg_Monetary_Value,
      count(ordernumber) Frequency,
      max(orderdate) last_order_date,
      (select max(orderdate) from Projects..sales_data_sample) max_order_date,
      Datediff(DD, max(orderdate),(select max(orderdate) from Projects..sales_data_sample)) Recency
  from Projects..sales_data_sample
  group by customername
),
rfm_calc as
(
  select r.*,
     NTILE(4) OVER(order by Recency desc) rfm_recency,
     NTILE(4) OVER(order by Frequency) rfm_frequency,
     NTILE(4) OVER(order by Monetary_Value) rfm_monetry
  from rfm r
)
select 
  c.*, rfm_recency+ rfm_frequency+ rfm_monetry as rfm_cell,
  cast(rfm_recency as varchar)+ cast(rfm_frequency as varchar)+ cast(rfm_monetry as varchar) rfm_cell_string
into #rfm
from rfm_calc c

select
 CUSTOMERNAME,rfm_recency, rfm_frequency, rfm_monetry,
 case
     When rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers'
	 When rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away, cannot lose'
	 When rfm_cell_string in (311,411,331) then 'New Customers'
	 When rfm_cell_string in (222,223,233,322) then 'Potential Churners'
	 When rfm_cell_string in (323,333,321,422,332,432) then 'active'
	 When rfm_cell_string in (433,434,443,444) then 'loyal'
 end rfm_segment
from #rfm


-- What Products are most often sold together?
select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from Projects..sales_data_sample p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM Projects..sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))
		, 1, 1, '') ProductCodes
from Projects..sales_data_sample s
order by 2 desc



--Which city has the highest number of sales in a specific country?
select city, sum (sales) Revenue
from Projects..sales_data_sample
where country = 'UK'
group by city
order by 2 desc



---Which is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from Projects..sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc