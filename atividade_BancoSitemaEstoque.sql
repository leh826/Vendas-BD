DELETE FROM CAIXA
USE LOJA
GO
CREATE TABLE CAIXA ----------------------- CRIANDO UMA TABELA DE CONTROLE DE CAIXA
   (
	DATA			DATE,
	SALDO_INICIAL	DECIMAL(10,2),
	SALDO_FINAL		DECIMAL(10,2),
	
   )
CREATE TABLE VENDAS ----------------------- CRIANDO UMA TABELA DE VENDAS
   (
	DATA		DATE,
	CODIGO		INT,
	VALOR		DECIMAL(10,2),
	--DESCR VARCHAR(30),
	--QTDE INT,
   )
CREATE TABLE ESTOQUE ----------------------- CRIANDO UMA TABELA DE ESTOQUES
(
	CODIGO		INT,
	DESCR		VARCHAR(30), 
	QTDE		INT
)
----------- INSERIDO PRODUTOS NA TABELA ESTOQUE
INSERT INTO ESTOQUE VALUES (1, 'TAPETE', 4);
INSERT INTO ESTOQUE VALUES (5, 'CAIXA', 5);
INSERT INTO ESTOQUE VALUES (2, 'LUSTRE', 3);
INSERT INTO ESTOQUE VALUES (3, 'CORTINA', 6);
INSERT INTO ESTOQUE VALUES (4, 'COLCHA DE CAMA', 6);
------------------------------------
------------- ADICIONADO CAMPOS EM VENDAS CASO JÁ TENHA A TABELA
ALTER TABLE VENDAS ADD DESCR VARCHAR(30)
ALTER TABLE VENDAS ADD QTDE INT;
------------------------------------
-------------------- INSERINDO VALOR NO CAIXA
INSERT INTO CAIXA VALUES (getdate(), 100, 100)
--------------------------------------
  SELECT * FROM CAIXA
  SELECT * FROM VENDAS
  SELECT * FROM ESTOQUE
--------------------------------------
---- GATILHO APÓS uma venda, ADD VALOR NO CAIXA
ALTER TRIGGER TG_ATUALIZA_SALDO
   ON VENDAS
        FOR INSERT
AS
    BEGIN
      DECLARE
   	   @VALOR	DECIMAL(10,2),
	   @DATA	DATE,
	   @QTDE INT,
	   @ESTOQUE INT,
	   @PRODUTO_ID INT

		SELECT @DATA = DATA, @VALOR = VALOR, @QTDE=QTDE, @PRODUTO_ID = CODIGO FROM INSERTED

		-- Verificar a quantidade no estoque
		SELECT @ESTOQUE = QTDE FROM ESTOQUE WHERE CODIGO = @PRODUTO_ID

    IF @QTDE > @ESTOQUE OR @QTDE = 0
    BEGIN
        ROLLBACK TRANSACTION
        PRINT ('Quantidade insuficiente no estoque para a venda.')
        RETURN
    END
	 -- Se houver quantidade suficiente, prosseguir com a atualização do caixa
	 UPDATE CAIXA 
			SET SALDO_FINAL = SALDO_FINAL + (@VALOR * @QTDE)
  			WHERE DATA = @DATA
 END
 ------------------------------------------------------
 --- GATILHO DEVOLUÇÇÃO DE UMA VENDA, ATUALIZA CAIXA DIMINUINDO VALOR
ALTER TRIGGER TG_ESTORNO_CAIXA
   ON VENDAS
       FOR DELETE
AS
    BEGIN
        DECLARE @VALOR DECIMAL(10,2),
                @DATA DATE,
                @QTDE INT,
                @CODIGO INT

        -- Cria um cursor para iterar sobre todas as linhas na tabela DELETED
        DECLARE cur CURSOR FOR SELECT DATA, VALOR, QTDE, CODIGO FROM DELETED
        OPEN cur

        -- Itera sobre todas as linhas na tabela DELETED
        FETCH NEXT FROM cur INTO @DATA, @VALOR, @QTDE, @CODIGO
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Atualiza o saldo para cada produto individualmente
            UPDATE CAIXA 
            SET SALDO_FINAL = SALDO_FINAL - (@VALOR * @QTDE)
            WHERE DATA = @DATA

            FETCH NEXT FROM cur INTO @DATA, @VALOR, @QTDE, @CODIGO
        END

        CLOSE cur
        DEALLOCATE cur
    END

----------------------------------------
--GATILHO  PARA APÓS uma venda, ATUALIZA ESTOQUE DIMINUINDO QUANTIDADE
ALTER TRIGGER TG_ATUALIZA_ESTOQUE
   ON VENDAS
       FOR INSERT
AS
    BEGIN
        DECLARE
    @CODIGO	INT,
    @QTDE	INT,
	@EXISTE INT

       SELECT @CODIGO = CODIGO, @QTDE = QTDE FROM INSERTED

	   -- Verificar se o produto existe no estoque
    SELECT @EXISTE = COUNT(*) FROM ESTOQUE WHERE CODIGO = @CODIGO

    IF @EXISTE = 0
    BEGIN
        ROLLBACK TRANSACTION
        PRINT ('O produto não foi resistrado no estoque.')
        RETURN
    END
    -- Se o produto existir, prosseguir com a atualização do estoque
    UPDATE ESTOQUE  
	SET QTDE = QTDE -  @QTDE
	WHERE CODIGO = @CODIGO
    END
------------------------------------
--GATILHO APÓS DEVOLUÇÃO DE uma venda, ATUALIZA ESTOQUE AUMENTANDO QUANTIDADE
ALTER TRIGGER TG_ESTORNO_ESTOQUE
   ON VENDAS
       FOR DELETE
AS
    BEGIN
        DECLARE @CODIGO INT,
                @QTDE INT

        -- Cria um cursor para iterar sobre todas as linhas na tabela DELETED
        DECLARE cur CURSOR FOR SELECT CODIGO, QTDE FROM DELETED
        OPEN cur

        -- Itera sobre todas as linhas na tabela DELETED
        FETCH NEXT FROM cur INTO @CODIGO, @QTDE
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Atualiza o estoque para cada produto individualmente
            UPDATE ESTOQUE
            SET QTDE = QTDE + @QTDE
            WHERE CODIGO = @CODIGO

            FETCH NEXT FROM cur INTO @CODIGO, @QTDE
        END

        CLOSE cur
        DEALLOCATE cur
    END

------------------------------------
-------------------------------------- ADD VENDAS
INSERT INTO VENDAS VALUES (GETDATE(), 1, 50,'TAPETE', 1)
INSERT INTO VENDAS VALUES (GETDATE(), 2, 10,'LUSTRE',2)
INSERT INTO VENDAS VALUES (GETDATE(),11, 10,'LUSTRE',3)
INSERT INTO VENDAS VALUES (GETDATE(), 3, 20, 'CORTINA',1)
INSERT INTO VENDAS VALUES (GETDATE(), 4, 30,'COLCHA DE CAMA',0)
INSERT INTO VENDAS VALUES (GETDATE(), 4, 30,'COLCHA DE CAMA',2)
--------------------------------------
DELETE FROM VENDAS WHERE CODIGO =1 --DELETANDO VENDA
--------------------------------------
  SELECT * FROM CAIXA
  SELECT * FROM VENDAS
  SELECT * FROM ESTOQUE
--------------------------------------