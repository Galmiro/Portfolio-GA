--SELECT * 
--FROM CovidVaccinations
--ORDER BY 3, 4


--SELECT * FROM CovidDeaths

-- Achico tabla seleccionando algunas columnas
SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population 
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



--ALTER TABLE CovidDeaths
--ALTER COLUMN population int


-- Total de muertes vs Total casos en Argentina
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as Porcentaje_Fallecidos
FROM CovidDeaths
WHERE location = 'Argentina'
and continent IS NOT NULL
ORDER BY 1,2


-- Total de casos vs Población
-- A dic/2021 un 11% de la población de Arg tuvo Covid
SELECT 
	location, 
	date, 
	population, 
	total_cases, 
	(total_cases/population)*100 as Porcentaje_Infeccion
FROM CovidDeaths
WHERE location = 'Argentina'
AND continent IS NOT NULL
ORDER BY 1,2


-- Países con mayores indices de infección en su población
SELECT 
	location, 
	cast(population as float) as Population, 
	MAX(total_cases) AS Valor_max_casos, 
	MAX((total_cases/population))*100 as Indice_Infeccion
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, Population
ORDER BY Indice_Infeccion DESC


-- Países con mayores indices de mortalidad  (muertes respecto a población)
SELECT 
	location, 
	MAX(total_deaths) AS Total_Muertes, 
	MAX((total_deaths/population))*100 as Indice_Mortalidad
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY indice_Mortalidad DESC


-- Países con mayor número de muertes por Covid
-- USA #1 787695, Argentina #13 116639
SELECT 
	location, 
	MAX(total_deaths) AS Total_Muertes
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Muertes DESC


-- Datos por continente, mayor número de muertes
SELECT 
	location, 
	MAX(total_deaths) AS Total_Muertes
FROM CovidDeaths
WHERE continent IS NULL
AND location not in (
	SELECT location 
	FROM CovidDeaths 
	WHERE location LIKE '%income%' or location LIKE 'international'
	)
GROUP BY location
ORDER BY Total_Muertes DESC



-- Datos Globales
SELECT 
	SUM(cast(new_cases as float)) AS Total_Casos, 
	SUM(cast(new_deaths as float)) as Total_Muertes, 
	SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as Porcentaje_Muertes
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Datos Globales por día (Covid Deaths)
SELECT date, SUM(cast(new_cases as float)) AS Casos_Diarios, SUM(cast(new_deaths as float)) as Muertes_x_dia, 
SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as Porcentaje_Muertes
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- Tabla vacunacion
SELECT * FROM CovidVaccinations

-- Test diarios en Argentina
SELECT date, SUM(CAST(new_tests AS float)) as Tests_Diarios
FROM CovidVaccinations
WHERE location = 'Argentina'
GROUP BY date


-- Juntando tablas
SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



-- Población Total vs Vacunacion
-- OVER(Partition by ...) calcula saldo acumulado por pais	

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations as float)) OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) as Total_Vacunado
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3




-- Paises con mayor n° de dosis suministradas
-- Argentina puesto #22
SELECT location, MAX(CAST(total_vaccinations AS float)) AS total_dosis
FROM CovidVaccinations
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_dosis DESC




-- Población Total vs Vacunacion
-- Argentina
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(CAST(vac.new_vaccinations as float)) OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) as Total_Vacunas
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location = 'Argentina'
ORDER BY 2,3



-- Tabla temp con query anterior
CREATE TABLE #PorcentajePoblacionVacunada
	(Continent varchar(255),
	Location varchar(255),
	Date datetime,
	population numeric,
	Dosis_diarias numeric,
	Saldo_acumulado numeric,
)

INSERT INTO #PorcentajePoblacionVacunada
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as float)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Total_Vacunas
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
--ORDER BY 2,3


-- Testeando nueva tabla
-- Primer Query
SELECT 
	*, 
	(Saldo_acumulado/population)*100 as Dosis_poblacion
FROM #PorcentajePoblacionVacunada
WHERE location = 'Argentina'
ORDER BY 2,3


-- Segunda Query
SELECT 
	location, 
	MAX(saldo_acumulado) as Total_dosis
FROM #PorcentajePoblacionVacunada
GROUP BY location
ORDER BY 2 DESC



-- Creando Vistas

-- Fallecidos por pais
CREATE VIEW Death_per_country AS
	SELECT 
		location, 
		MAX(total_deaths) AS Total_Muertes
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location
