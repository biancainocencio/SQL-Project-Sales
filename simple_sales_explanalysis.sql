
--1. Creating columns `min_price` and `max_price`
ALTER TABLE produtos
ADD	min_price INT;

ALTER TABLE produtos
ADD	max_price INT;

--2. Populating the `min_price` and `max_price` columns
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

--Check results.
SELECT nome_produto, min_price, max_price
FROM produtos
GROUP BY nome_produto;

--3. Updating prices based on upper and lower bounds
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

--EXPLORATORY ANALYSES

--What have the sales been over the years?
--Extract the year and then collapse the sales data by year.
SELECT 
	strftime('%Y', data_venda) AS Year,
    COUNT(id_venda) AS Total_Orders
FROM vendas
GROUP BY Year
ORDER BY Year

--Filtering only for peak months (November, December, January)
SELECT
	strftime('%Y', data_venda) AS Year,
	strftime('%m', data_venda) AS Month,
	COUNT(id_venda) AS Total_Orders
FROM vendas
WHERE Month IN ('01', '11', '12') --These need to be strings because `strftime` extracts the date numbers as strings.
GROUP BY Year, Month
ORDER BY Year

--Performance of suppliers and categories
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

--Sales of three specific suppliers
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
