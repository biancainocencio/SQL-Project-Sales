# SQL Project: Sales Data
Simple project in SQL that consisted of treating and running some exploratory commands on a database. Ran using [SQLite](https://sqliteonline.com/). SQLite docs available [here](https://www.sqlite.org/docs.html). 

> [!NOTE]
> To run the queries below and develop a project of your own, you can download the [sales database from this repository](https://github.com/biancainocencio/SQL-Project-Sales/blob/main/banco_de_dados_vendas.db). This was a simple study I conducted to brush up on some specific SQL skills I felt needed sharpening. This repo is not intended to be a fully developed data analysis project. Also, please, note that some of the text in the database is in Brazilian Portuguese.

# Exploring the data
> _If you want to use this project as a way to practice your SQL skills, I suggest you do some data exploration of your own and document it. Feel free to fork this project and work on top of it! I ran a few counts, understood the averages and max and min values of the columns, and analyzed the prices. In my data exploration, I noticed the prices were very weird, so I set a price interval for each product and treated the data to ensure the prices respected such intervals._

# Treating the data
**1. Creating columns `min_price` and `max_price`**
Unlike other systems, SQLite does not support adding multiple columns in a single ALTER TABLE statement. You must execute separate ALTER TABLE ADD COLUMN statements for each column:
```sql
ALTER TABLE table_name
ADD column_name1 INT NULL;

ALTER TABLE table_name
ADD column_name2 INT NULL;
```

```sql
ALTER TABLE produtos
ADD	min_price INT;

ALTER TABLE produtos
ADD	max_price INT;
```

**2. Populating the `min_price` and `max_price` columns**
```sql
UPDATE produtos
SET 
    max_price = CASE
        WHEN nome_produto = 'Celular' THEN 5000
        WHEN nome_produto = 'Camisa' THEN 200
        WHEN nome_produto = 'Livro de Ficção' THEN 200
        WHEN nome_produto ='Bola de Futebol' THEN 100
        WHEN nome_produto ='Chocolate' THEN 20
        ELSE max_price
    END,
    min_price = CASE
        WHEN nome_produto = 'Celular' THEN 80
        WHEN nome_produto = 'Camisa' THEN 80
        WHEN nome_produto = 'Livro de Ficção' THEN 10
		WHEN nome_produto ='Bola de Futebol' THEN 20
        WHEN nome_produto ='Chocolate' THEN 5
        ELSE min_price
    END

-- Check results.
SELECT nome_produto, min_price, max_price
FROM produtos
GROUP BY nome_produto;
```

**3. Updating prices based on upper and lower bounds**

```sql
--Adjust prices based on min and max prices

UPDATE produtos
SET preco = CASE
	WHEN preco < min_price THEN min_price
    WHEN preco > max_price THEN max_price
    ELSE
    	preco
END
WHERE preco < min_price OR preco > max_price

--Check results
SELECT 
	nome_produto,
    max(preco) AS 'real_max_price',
    max_price,
    min(preco) AS 'real_min_price',
    min_price
FROM produtos
GROUP BY nome_produto
```

# Analyzing data
**1. What have the sales been over the years?**

```sql
--Extract the year and then collapse the sales data by year.
SELECT 
	strftime('%Y', data_venda) AS Year,
    COUNT(id_venda) AS Total_Orders
FROM vendas
GROUP BY Year
ORDER BY Year
```

Filtering only for peak months (November, December, January):

```sql
SELECT
	strftime('%Y', data_venda) AS Year,
	strftime('%m', data_venda) AS Month,
	COUNT(id_venda) AS Total_Orders
FROM vendas
WHERE Month IN ('01', '11', '12') --These need to be strings because `strftime` extracts the date numbers as strings.
GROUP BY Year, Month
ORDER BY Year
```

**2. Exploratory analysis on the performance of suppliers and categories**
```sql
--Suppliers' performance during peak months
SELECT 
	strftime('%Y/%m', v.data_venda) AS 'Ano/Mes',
    f.nome AS Nome_Fornecedor,
    COUNT(i.produto_id) AS Qtd_Vendas
FROM itens_venda i 
JOIN vendas v ON v.id_venda = i.venda_id
JOIN produtos p On p.id_produto = i.produto_id
JOIN fornecedores f ON f.id_fornecedor = p.fornecedor_id
GROUP BY Nome_Fornecedor, "Ano/Mes"
ORDER BY Nome_Fornecedor, "Ano/Mes";

--Category performance during peak months 
SELECT 
	strftime("%Y", v.data_venda) AS "Ano", 
    c.nome_categoria AS Nome_Categoria, 
    COUNT(iv.produto_id) AS Qtd_Vendas
FROM itens_venda iv
JOIN vendas v ON v.id_venda = iv.venda_id
JOIN produtos p ON p.id_produto = iv.produto_id
JOIN categorias c ON c.id_categoria = p.categoria_id
WHERE strftime("%m", v.data_venda) = "11"
GROUP BY Nome_Categoria, "Ano"
ORDER BY "Ano", Qtd_Vendas DESC;
```

**3. Analyzing sales of three specific suppliers**
```sql
SELECT "Ano/Mes",
 SUM(CASE WHEN Nome_Fornecedor="NebulaNetworks" THEN Qtd_Vendas ELSE 0 END) AS Qtd_Vendas_NebulaNetworks,
 SUM(CASE WHEN Nome_Fornecedor="HorizonDistributors" THEN Qtd_Vendas ELSE 0 END) AS Qtd_Vendas_HorizonDistributors,
 SUM(CASE WHEN Nome_Fornecedor="AstroSupply" THEN Qtd_Vendas ELSE 0 END) AS Qtd_Vendas_AstroSupply
FROM (
   SELECT strftime("%Y/%m", v.data_venda) AS "Ano/Mes", f.nome AS Nome_Fornecedor, COUNT(iv.produto_id) AS Qtd_Vendas
   FROM itens_venda iv
   JOIN vendas v ON v.id_venda = iv.venda_id
   JOIN produtos p ON p.id_produto = iv.produto_id
   JOIN fornecedores f ON f.id_fornecedor = p.fornecedor_id
   WHERE Nome_Fornecedor="NebulaNetworks" OR Nome_Fornecedor="HorizonDistributors" OR Nome_Fornecedor="AstroSupply"
   GROUP BY Nome_Fornecedor, "Ano/Mes"
   ORDER BY "Ano/Mes", Qtd_Vendas
  )
GROUP BY "Ano/Mes";
```

```sql
--How much each supplier contributed to sales

SELECT
	nome_categoria,
    qtd_vendas,
    ROUND(100.0*qtd_vendas/(SELECT COUNT(*) FROM itens_venda), 2) || '%' AS Percentage
FROM(
  SELECT --Query to retrieve total sales by supplier
      strftime('%Y', v.data_venda) AS "Ano", 
      c.nome_categoria AS Nome_Categoria, 
      COUNT(iv.produto_id) AS Qtd_Vendas
  FROM itens_venda iv
  JOIN vendas v ON v.id_venda = iv.venda_id
  JOIN produtos p ON p.id_produto = iv.produto_id
  JOIN categorias c ON c.id_categoria = p.categoria_id
  GROUP BY Nome_Categoria
  ORDER BY Qtd_Vendas DESC
)
```

The query above returns something of the sort:
| Nome_Categoria | Qtd_Vendas | Percentage |
|----------------|------------|------------|
| Eletrônicos    | 43446      | 28.96%     |
| Vestuário      | 41274      | 27.51%     |
| Alimentos      | 21922      | 14.61%     |
| Esportes       | 21782      | 14.52%     |
| Livros         | 21610      | 14.40%     |

From here, you can use R, Python, or Excel and Google Sheets to create your dashboards and reports and train some skills! 

Have fun. 😸
