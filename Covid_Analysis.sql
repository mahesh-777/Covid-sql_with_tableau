
--Query for the total deaths
Select *
From CovidAnalysis..CovidDeaths
Where continent is not null 
order by location, date

--Query for total_deaths, total_cases By location and date
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidAnalysis..CovidDeaths
Where continent is not null 
order by location, date

--Query for Death rate compared to population
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidAnalysis..CovidDeaths
Where location like '%india%'
and continent is not null 
order by location, date

--Percentage of population infected with 
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidAnalysis..CovidDeaths
--Where location like '%india%'
order by location, date


--Countries with highest infection rate compared to the population

SELECT location, population, MAX(total_cases) AS TotalInfectionRate, MAX((total_cases/population))*100 AS TotalPopulationInfected
FROM CovidAnalysis..CovidDeaths
GROUP BY location, population
ORDER BY TotalPopulationInfected DESC

--Countries with highest death count

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeaths
FROM CovidAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY location 
ORDER BY TotalDeaths DESC

--Total Population vs Vaccinations
--Countries with least Covid Vaccinations

SELECT d.location, d.date, d.population, v.new_vaccinations
FROM CovidAnalysis..CovidDeaths d
JOIN CovidAnalysis..CovidVaccinations v
	ON d.location = v.location
	 AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY location, date

--Total Cases with respect to population 
SELECT  location, MAX(population) AS population, MAX(total_cases) AS Total_Cases, (MAX(total_cases)/MAX(population)) as tp
from CovidAnalysis..CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY location
ORDER BY tp DESC

--Get new vaccination as per the countries per day
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM CovidAnalysis..CovidDeaths d
JOIN CovidAnalysis..CovidVaccinations v
	ON d.location = v.location
	 AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY continent, location

--Get Rolling Sum of vaccination till the last day
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM CovidAnalysis..CovidDeaths d
JOIN CovidAnalysis..CovidVaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent is not null
ORDER BY d.location, d.date

--Using CTE to perform calculation on partition by in previous query

WITH popVSvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(v.new_vaccinations AS INT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM CovidAnalysis..CovidDeaths d
JOIN CovidAnalysis..CovidVaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent is not null
--ORDER BY d.location, d.date
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentVaccination
FROM
popVSvac

--Using Temporary table to perform calculation by partition
SET ANSI_WARNINGS OFF
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population float,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(v.new_vaccinations AS BIGINT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM CovidAnalysis..CovidDeaths d
JOIN CovidAnalysis..CovidVaccinations v
	ON d.location = v.location
		AND d.date = v.date
--WHERE d.continent is not null
--ORDER BY d.location, d.date
SELECT *, (RollingPeopleVaccinated/population)*100
FROM
#PercentPopulationVaccinated


--Create View to store data for later visualization
DROP TABLE IF EXISTS PercentPopulationVaccinated
DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(v.new_vaccinations AS BIGINT)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM CovidAnalysis..CovidDeaths d
JOIN CovidAnalysis..CovidVaccinations v
	ON d.location = v.location
		AND d.date = v.date
WHERE d.continent is not null


