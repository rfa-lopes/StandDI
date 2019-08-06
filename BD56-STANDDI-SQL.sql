--Apagar todas as tabelas	
	drop table Moradas cascade constraints;
	drop table Entidades cascade constraints;
	drop table Vendedores cascade constraints;
	drop table Clientes cascade constraints;
	drop table Empresas cascade constraints;
	drop table Veiculos cascade constraints;
	drop table Comprou cascade constraints;
	drop table Marcas cascade constraints;
	drop table Test_Drive cascade constraints;
	drop table Tipos cascade constraints;
	drop table Carros cascade constraints;
	drop table Motas cascade constraints;

--Criação da tabela: Moradas
	create table Moradas (
		Codigo_Postal varchar(20),
		Pais varchar(100),
		Localidade varchar(100) not null,
		primary key(Codigo_Postal, Pais)
	);

--Criação da tabela: Entidades
	create table Entidades (
		NIF varchar(9),
		Codigo_Postal varchar(20) not null,
		Pais varchar(100) not null,
		Nome varchar(100) not null,
		Telefone varchar(9) not null,
		Email varchar(50) not null,
		Rua_Numero varchar(100) not null,
		primary key (NIF),
		foreign key (Código_Postal, Pais) references Moradas
	);

--Criação da tabela: Vendedores
	create table Vendedores (
		NIF varchar(9),
		Salario number(6,2) not null check (Salário > 0),
		primary key (NIF),
		foreign key (NIF) references Entidades
	);

--Criação da tabela: Clientes
	create table Clientes (
		NIF varchar(9),
		primary key (NIF),
		foreign key (NIF) references Entidades
	);

--Criação da tabela: Empresas
	create table Empresas (
		NIF varchar(9),
		Desconto number(2) not null check (Desconto > 0),
		primary key (NIF),
		foreign key (NIF) references Clientes
	);

--Criação da tabela: Marcas
	create table Marcas (
		Marca varchar(50),
		Modelo varchar(50),
		primary key (Marca,Modelo)
	);
    
--Criação da tabela: Veiculos
	create table Veiculos (
		Matricula varchar (15) primary key,
		Cor varchar(30) not null,
		Tipo_Combustivel varchar(30) not null,
		Ano number (4) not null,
		Quilometragem number (12) not null, check (Quilometragem > 0),
		Preco number (10,2) not null, check (Preço > 0),
        Marca varchar(50) not null,
		Modelo varchar (50) not null,
		NIF varchar(9) not null,
		foreign key (Nif) references Entidades,
		foreign key (Marca, Modelo) references Marcas
	);
    
--Criação da tabela: Comprou
	create table Comprou (
		Matricula varchar(15),
		NifC varchar(9),
		NifV varchar(9),
		primary key (Matricula),
		foreign key (Matricula) references Veiculos,
		foreign key (NIFC) references Clientes(NIF),
		foreign key (NIFV) references Vendedores(NIF),
		check (NifC <> NifV)
	);

--Criação da tabela: Test_Drive
	create table Test_Drive (
		Matricula varchar(15),
		NIF varchar(9),
		Data date not null,
		primary key (Matricula,NIF),
		foreign key (Matricula) references Veiculos,
		foreign key (NIF) references Clientes
	);

--Criação da tabela: Tipos
	create table Tipos (
		Nome_Tipo varchar(30) primary key
	);

--Criação da tabela: Carros
	create table Carros (
		Matricula varchar (15) primary key,
		Portas number not null,
		Lugares number(2) not null,
		Nome_Tipo varchar(30),
		foreign key (Matricula) references Veiculos,
		foreign key (Nome_Tipo) references Tipos
	);

--Criação da tabela: Motas
	create table Motas (
		Matricula varchar(15) primary key,
		Cilindrada number(4) not null, check (Cilindrada > 0),
		foreign key (Matricula) references Veiculos
	);
    
--views

drop view veiculosNaoVendidos cascade constraints;
drop view veiculosVendidosPorVendedor cascade constraints;
drop view onlyMotas cascade constraints;
drop view onlyCarros cascade constraints;
drop view addMorada cascade constraints;

create or replace view veiculosVendidosporVendedor as 
(select nome as nome, count(matricula) as soma
from comprou inner join entidades on (nifV = nif)
group by nome);

CREATE OR REPLACE FORCE VIEW  "veiculosNaoVendidos" ("MATRICULA", "MODELO", "MARCA", "COR") AS 
  (SELECT matricula, modelo, marca, cor
      FROM VEICULOS
      WHERE NOT EXISTS 
      (SELECT * 
          FROM COMPROU
          WHERE VEICULOS.matricula = COMPROU.matricula))

  CREATE OR REPLACE FORCE VIEW  "ONLYMOTAS" ("MATRICULA", "COR", "TIPO_COMBUSTIVEL", "ANO", "QUILOMETRAGEM", "PRECO", "MARCA", "MODELO", "NIF", "CILINDRADA") AS 
  (select matricula, cor,Tipo_Combustivel,ano,Quilometragem,Preco,marca,modelo,nif,Cilindrada
		from veiculos inner join motas using (matricula))

  CREATE OR REPLACE FORCE VIEW  "ONLYCARROS" ("MATRICULA", "COR", "TIPO_COMBUSTIVEL", "ANO", "QUILOMETRAGEM", "PRECO", "MARCA", "MODELO", "NIF", "PORTAS", "LUGARES", "NOME_TIPO") AS 
  (select matricula, cor,Tipo_Combustivel,ano,Quilometragem,Preco,marca,modelo,nif,portas,lugares,nome_tipo
		from veiculos inner join carros using (matricula))

CREATE OR REPLACE FORCE VIEW  "ADDMORADA" ("CODIGO_POSTAL", "PAIS", "NIF", "NOME", "TELEFONE", "EMAIL", "RUA_NUMERO", "LOCALIDADE") AS 
  (select "CODIGO_POSTAL","PAIS","NIF","NOME","TELEFONE","EMAIL","RUA_NUMERO","LOCALIDADE" from entidades natural inner join moradas)

--triggers

create or replace trigger addTipo 
    before insert on Carros
    for each row 
    declare
        existeTipo number;
    begin 
        select count(nome_tipo) into existeTipo
        from tipos
        where nome_tipo = :new.nome_tipo;
        
        if existeTipo = 0 then
            insert into tipos values (:new.nome_tipo);
        end if;
    end;
    
    create or replace trigger addMarca
    before insert on Veiculos
    for each row
    declare existeMarca number; existeModelo number;
      begin 
        select count(marca) into existeMarca
        from Marcas
        where marca = :new.marca;
        
        select count(modelo) into existeModelo
        from Marcas
        where modelo = :new.modelo;
        
        if existeMarca = 0 or existeModelo = 0 then
            insert into marcas values (:new.marca,:new.modelo);
        end if;
    end;

   CREATE OR REPLACE TRIGGER  "ADDMOTA" 
    	instead of  insert  on onlyMotas
    	for each row
    	begin
    		insert into veiculos values (:new.Matricula,:new.cor,:new.Tipo_Combustivel,:new.ano,:new.Quilometragem,:new.Preco,:new.marca,:new.modelo,:new.nif);
    	    insert into motas values (:new.Matricula,:new.cilindrada);
    end;

    CREATE OR REPLACE TRIGGER  "ADDMORADAANDENTITY" 
    	instead of  insert  on addMorada
    	for each row
   		declare 
    	existePais number; existeCodigoPostal number;
    	begin
    	select count(Codigo_Postal) into existeCodigoPostal
    	from moradas 
    	where Codigo_Postal=:new.Codigo_Postal;

    	select count(Pais) into existePais
    	from moradas
    	where pais=:new.Pais;

    	if existeCodigoPostal=0 or existePais=0 then 
    	insert into moradas values (:new.Codigo_Postal,:new.pais,:new.Localidade);
    	end if;
    	
    	insert into entidades values(:new.nif,:new.Codigo_Postal,:new.pais,:new.nome,:new.Telefone,:new.Email,:new.Rua_Numero);
    end;

    CREATE OR REPLACE TRIGGER  "ADDCARRO" 
    	instead of  insert  on onlyCarros
    	for each row
    	begin
    		insert into veiculos values (:new.Matricula,:new.cor,:new.Tipo_Combustivel,:new.ano,:new.Quilometragem,:new.Preco,:new.marca,:new.modelo,:new.nif);
    	    insert into carros values (:new.Matricula,:new.portas,:new.lugares,:new.nome_tipo);
    	    	end;


--Inserção de dados:

insert into Moradas values ('2970-111','Portugal','Almeida');
insert into Moradas values ('2970-112','Portugal','Almada');
insert into Moradas values ('2970-113','Portugal','Sesimbra');
insert into Moradas values ('2970-222','França','Lyon');
insert into Moradas values ('2970-223','França','Paris');
insert into Moradas values ('2970-333','Itália','Roma');
insert into Moradas values ('2970-334','Itália','Veneza');
insert into Moradas values ('2970-444','Japão','Tóquio');
insert into Moradas values ('2970-445','Japão','Osaka');
insert into Moradas values ('2970-446','Japão','Nagoya');

insert into Entidades values ('111111111','2970-111','Portugal','Rodrigo Lopes','911111111','Rodrigo@mail','Rua 1');
insert into Entidades values ('222222222','2970-223','França','Francisco Delgado','922222222','Francisco@mail','Rua 2');
insert into Entidades values ('333333333','2970-222','França','David Daud','933333333','David@mail','Rua 3');
insert into Entidades values ('444444444','2970-333','Itália','Zé','944444444','Ze@mail','Rua 4');
insert into Entidades values ('555555555','2970-333','Itália','Esmeralda Santos da Conceição Paiva Silva Lopes Delgada Daud','955555555','Diabinha@mail','Rua 5');
insert into Entidades values ('666666666','2970-333','Itália','Montadino Jofâncio Almeida da Costa','966666666','Montadino@mail','Rua 6');
insert into Entidades values ('777777777','2970-446','Japão','Joaquim Francilio','977777777','Joaquim@mail','Rua 7');
insert into Entidades values ('888888888','2970-112','Portugal','Diogo Faria','988888888','Diogo@mail','Rua 8');
insert into Entidades values ('999999999','2970-444','Japão','Francisca Almeia','099999999','Francisca@mail','Rua 9');
insert into Entidades values ('000000000','2970-111','Portugal','João Manuel','900000000','Joao@mail','Rua 0');

insert into Entidades values ('010101010','2970-111','Portugal','José Lopes','901010101','Vendedor111@mail','Rua 1');
insert into Entidades values ('020202020','2970-111','Portugal','Sónia Faria','902020202','Vendedor222@mail','Rua 1');
insert into Entidades values ('030303030','2970-334','Itália','Uracilio Conde','903030303','Vendedor333@mail','Rua 2');
insert into Entidades values ('040404040','2970-222','França','Manuel Oliveira','904040404','Vendedor444@mail','Rua 3');
insert into Entidades values ('050505050','2970-444','Japão','Artur Miguel Dias','905050505','Vendedor555@mail','Rua 0');

insert into Entidades values ('121212121','2970-113','Portugal','Cisco','912121212','Empresa222@mail','Rua 1');
insert into Entidades values ('131313131','2970-111','Portugal','Talho Almeida','913131313','Empresa333@mail','Rua 1');
insert into Entidades values ('141414141','2970-222','França','Siemens','914141414','Empresa444@mail','Rua 2');
insert into Entidades values ('151515151','2970-445','Japão','Samsung','915151515','Empresa555@mail','Rua 3');
insert into Entidades values ('161616161','2970-333','Itália','Nokia','916161616','Empresa666@mail','Rua 3');

insert into Clientes values ('111111111');
insert into Clientes values ('222222222');
insert into Clientes values ('333333333');
insert into Clientes values ('444444444');
insert into Clientes values ('555555555');
insert into Clientes values ('666666666');
insert into Clientes values ('777777777');
insert into Clientes values ('888888888');
insert into Clientes values ('999999999');
insert into Clientes values ('000000000');
insert into Clientes values ('121212121');
insert into Clientes values ('131313131');
insert into Clientes values ('141414141');
insert into Clientes values ('151515151');
insert into Clientes values ('161616161');

insert into Vendedores values ('010101010',500.50);
insert into Vendedores values ('020202020',600.00);
insert into Vendedores values ('030303030',1000.00);
insert into Vendedores values ('040404040',5000.01);
insert into Vendedores values ('050505050',250.00);

insert into Empresas values ('121212121',10);
insert into Empresas values ('131313131',90);
insert into Empresas values ('141414141',50);
insert into Empresas values ('151515151',35);
insert into Empresas values ('161616161',25);

insert into Marcas values ('Peugeot','2008');
insert into Marcas values ('Peugeot','3008');
insert into Marcas values ('Peugeot','5008');
insert into Marcas values ('Mercedes','A200');
insert into Marcas values ('Audi','A4');
insert into Marcas values ('Audi','A1');
insert into Marcas values ('BMW','X6');
insert into Marcas values ('Smart','Mini');
insert into Marcas values ('Renault','Zoe');
insert into Marcas values ('Seat','Ibiza');

insert into Marcas values ('Suzuki','GSX-R125');
insert into Marcas values ('Honda','CB300R');
insert into Marcas values ('Benelli','TNT125');
insert into Marcas values ('Honda','CB125F');

insert into Veiculos values ('11-AA-11','Rosa','Gasóleo',2011,90000,25000,'Mercedes','A200','111111111');
insert into Veiculos values ('22-AA-22','Azul','Gasóleo',2017,20000,70000,'Peugeot','2008','111111111');
insert into Veiculos values ('22-AA-23','Preto','Gasolina',2016,30000,60000,'Peugeot','2008','111111111');
insert into Veiculos values ('22-AA-24','Vermelho','Gasolina',2015,40000,50000,'Peugeot','2008','222222222');
insert into Veiculos values ('22-AA-25','Azul','Gasóleo',2009,70000,45000,'Peugeot','5008','333333333');
insert into Veiculos values ('33-AA-33','Azul','Gasóleo',2016,50000,20000,'Audi','A1','444444444');
insert into Veiculos values ('44-AA-22','Amarelo','Gasóleo',2017,60000,25000,'BMW','X6','555555555');
insert into Veiculos values ('77-CR-77','Azul','Eléctrico',2018,00100,99999,'Renault','Zoe','777777777');

insert into Veiculos values ('22-BB-26','Preto','Gasolina',2013,10000,20000,'Suzuki','GSX-R125','111111111');
insert into Veiculos values ('23-BB-27','Azul','Eléctrico',2014,15000,35000,'Benelli','TNT125','222222222');
insert into Veiculos values ('24-BB-28','Preto','Gasolina',2015,10000,45000,'Honda','CB125F','888888888');
insert into Veiculos values ('25-BB-29','Azul','Gasóleo',2011,20000,70000,'Honda','CB300R','666666666');
insert into Veiculos values ('26-BB-30','Vermelho','Gasolina',2017,34000,70000,'Honda','CB125F','444444444');
insert into Veiculos values ('27-BB-31','Rosa','Gasolina',2017,46000,45000,'Honda','CB125F','999999999');

insert into Tipos values ('Familiar');
insert into Tipos values ('Carrinha');
insert into Tipos values ('Comercial');
insert into Tipos values ('Carro de Corrida');

insert into Carros values ('11-AA-11',5,5,'Carrinha');
insert into Carros values ('22-AA-22',5,5,'Familiar');
insert into Carros values ('22-AA-23',5,5,'Familiar');
insert into Carros values ('22-AA-24',5,5,'Comercial');
insert into Carros values ('22-AA-25',5,7,'Familiar');
insert into Carros values ('33-AA-33',5,5,'Comercial');
insert into Carros values ('44-AA-22',5,5,'Familiar');
insert into Carros values ('77-CR-77',2,2,'Carro de Corrida');

insert into Motas values ('22-BB-26',0125);
insert into Motas values ('23-BB-27',0125);
insert into Motas values ('24-BB-28',0050);
insert into Motas values ('25-BB-29',5000);
insert into Motas values ('26-BB-30',0050);
insert into Motas values ('27-BB-31',0050);

insert into Comprou values ('27-BB-31','999999999','010101010');
insert into Comprou values ('25-BB-29','444444444','010101010');
insert into Comprou values ('22-AA-24','999999999','030303030');
insert into Comprou values ('77-CR-77','444444444','020202020');
insert into Comprou values ('44-AA-22','999999999','030303030');

insert into Test_Drive values ('77-CR-77','111111111',to_date('2018-05-27','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','222222222',to_date('2018-07-07','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','333333333',to_date('2018-06-01','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','444444444',to_date('2018-06-02','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','555555555',to_date('2018-04-03','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','666666666',to_date('2018-06-04','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','888888888',to_date('2018-04-05','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','999999999',to_date('2018-04-06','YYYY-MM-DD'));
insert into Test_Drive values ('77-CR-77','000000000',to_date('2018-05-17','YYYY-MM-DD'));