SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4

--Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

SELECT * FROM PortfolioProject..CovidDeaths WHERE total_cases = 0
DELETE PortfolioProject..CovidDeaths WHERE total_cases = 0

--Looking at the Total Cases vs Total Deaths
--shows likehood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like'Canada'
ORDER BY 1, 2

--looking at total cases vs population
--shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS 'percent population infected'
FROM PortfolioProject..CovidDeaths
--WHERE location like'Canada'
WHERE continent IS NOT NULL
ORDER BY 1, 2

--looking at which country with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS 'highest infection Country', MAX((total_cases/population))*100 AS 'percent population infected'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 'percent population infected' DESC

--showing countries with highest death count per population
UPDATE PortfolioProject..CovidDeaths
SET continent = NULL
WHERE location='World' 
OR location='High income' 
OR location='Upper middle income'
OR location='Lower middle income'
OR location='Europe'
OR location='Asia'
OR location='North America'
OR location='South America'
OR location='European Union'

SELECT location, MAX(total_deaths) AS 'total deaths count'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 'total deaths count' DESC

--let us break things down by continent
SELECT location, MAX(total_deaths) AS 'total deaths count'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE 'High income' AND location NOT LIKE 'Upper middle income' AND location NOT LIKE 'Lower middle income'
GROUP BY location
ORDER BY 'total deaths count' DESC

--Global numbers
SELECT date,SUM(new_cases) AS newCovidCases, SUM(new_deaths) AS newDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS deathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE 'High income' AND location NOT LIKE 'Upper middle income' AND location NOT LIKE 'Lower middle income' 
GROUP BY date
HAVING SUM(new_cases) <> 0
ORDER BY 1, 2

SELECT SUM(new_cases) AS newCovidCases, SUM(new_deaths) AS newDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS deathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE 'High income' AND location NOT LIKE 'Upper middle income' AND location NOT LIKE 'Lower middle income' 
--GROUP BY date
--HAVING SUM(new_cases) <> 0
--ORDER BY 1, 2


--looking at total population vs vaccinations
SELECT *
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent = 'Africa' or dea.continent = 'Asia' or dea.continent = 'Europe' or dea.continent = 'North America' or dea.continent = 'Oceania' or dea.continent = 'South America'
ORDER BY 1,2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
-- ,(rollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS Dea
JOIN PortfolioProject..CovidVaccinations AS Vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent = 'Africa' or dea.continent = 'Asia' or dea.continent = 'Europe' or dea.continent = 'North America' or dea.continent = 'Oceania' or dea.continent = 'South America'
ORDER BY 1,2,3

--use CTE
WITH PopVsVac
(Continent, Location, Date, Population,NewVaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent = 'Africa' or dea.continent = 'Asia' or dea.continent = 'Europe' or dea.continent = 'North America' or dea.continent = 'Oceania' or dea.continent = 'South America'
)
SELECT *, (RollingPeopleVaccinated / Population)*100 AS VaccinatedRate
FROM PopVsVac -- further calculation can be carried on


--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths Dea
JOIN PortfolioProject..CovidVaccinations Vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent = 'Africa' or dea.continent = 'Asia' or dea.continent = 'Europe' or dea.continent = 'North America' or dea.continent = 'Oceania' or dea.continent = 'South America'

SELECT *, (rollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

--CREATE VIEW TO STORE DATA FOR LATER VISUALIZATIONS
CREATE VIEW VaccinatedView AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent = 'Africa' or dea.continent = 'Asia' or dea.continent = 'Europe' or dea.continent = 'North America' or dea.continent = 'Oceania' or dea.continent = 'South America'

SELECT *
FROM VaccinatedView