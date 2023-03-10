--SELECT *
--FROM CovidVaccinations$
--ORDER BY 3,4

--SELECT *
--FROM CovidDeaths$
--ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1,2

--Total cases vs total deaths
SELECT Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2

--total cases vs population
SELECT Location, date, total_cases, new_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidDeaths$
--WHERE location like '%states%'
ORDER BY 1,2

--highest infection rates
SELECT Location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths$
--WHERE location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc

--Highest death count per population
SELECT Location, MAX(CAST(total_deaths as int)) as totalDeaths
FROM CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY Location
ORDER BY totalDeaths desc

--by continent
SELECT location, MAX(CAST(total_deaths as int)) as totalDeaths
FROM CovidDeaths$
--WHERE location like '%states%'
WHERE continent is null
GROUP BY location
ORDER BY totalDeaths desc

--global data
SELECT SUM(CAST(new_cases as int)) as totalCases, SUM(CAST(new_deaths as int)) as totalDeaths, SUM(CAST(new_cases as int))/SUM(CAST(new_deaths as int))*100 as DeathPercentage
FROM CovidDeaths$
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

--total population vs vaccinations
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CONVERT(int,vacc.new_vaccinations)) 
OVER (Partition by death.location ORDER BY	death.location, death.date) as RollingTotalVaccinations
FROM CovidDeaths$ death
JOIN CovidVaccinations$ vacc
	On death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
ORDER BY 1,2

--CTE useage
WITH PopvsVac (continent, location, date, population, newVaccinations, RollingTotalVaccinations)
as
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CONVERT(int,vacc.new_vaccinations)) 
OVER (Partition by death.location ORDER BY	death.location, death.date) as RollingTotalVaccinations
FROM CovidDeaths$ death
JOIN CovidVaccinations$ vacc
	On death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
--ORDER BY 2,3
)

SELECT *, (RollingTotalVaccinations/population)*100 as percentPopulationVaccinated
FROM PopvsVac

--TempTable useage

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
locatin nvarchar(255),
date datetime,
population numeric,
newVaccinations numeric,
RollingTotalVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CONVERT(int,vacc.new_vaccinations)) 
OVER (Partition by death.location ORDER BY	death.location, death.date) as RollingTotalVaccinations
FROM CovidDeaths$ death
JOIN CovidVaccinations$ vacc
	On death.location = vacc.location
	and death.date = vacc.date
--WHERE death.continent is not null
--ORDER BY 2,3

SELECT *, (RollingTotalVaccinations/population)*100
FROM #PercentPopulationVaccinated

--views to store data for visuals
CREATE VIEW PercentPopulationVaccinated as
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CONVERT(int,vacc.new_vaccinations)) 
OVER (Partition by death.location ORDER BY	death.location, death.date) as RollingTotalVaccinations
FROM CovidDeaths$ death
JOIN CovidVaccinations$ vacc
	On death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
--ORDER BY 2,3
