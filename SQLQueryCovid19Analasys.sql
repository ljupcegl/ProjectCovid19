SELECT *
FROM CovidProject..CovidDeaths
order by 3, 4

select *
From CovidProject..CovidVactinations
order by 3, 4

Select Location, date, total_cases, new_cases, total_deaths, population
from CovidProject..CovidDeaths
order by 1,2

-- Loking at Total Cases vs Total Deaths

Select Location, date, total_cases, total_deaths, convert(float, total_deaths)/convert(float,total_cases)*100 as 'percentage_rate'
from CovidProject..CovidDeaths
--where location = 'North Macedonia'
order by 4 desc


-- Loking Total Cases vs Population
-- Show what percentage of populatin contracted Covid19

Select Location, date,  population, total_cases, convert(float, total_cases)/convert(float,population)*100 as 'percentage_rate'
from CovidProject..CovidDeaths
--where location = 'North Macedonia'
order by 1

-- Looking at Countries with Highest infection rate to Population

Select Location, population, MAX(total_cases) HigestInfectonCount, MAX(convert(float, total_cases)/convert(float,population))*100 as PercentagePopulationInfected
from CovidProject..CovidDeaths
--where location = 'North Macedonia'
group by Location, population
order by PercentagePopulationInfected desc

--Showing Countries whit Highest Death Rate to Population

Select  Location, 
		population, 
		MAX(cast(total_deaths as int)) 
		HigestDeathCount, MAX(convert(float, total_deaths)/convert(float,population))*100 as PercentagePopulationDeaths
from CovidProject..CovidDeaths
where continent is not null
-- and continent = 'Europe'
group by Location, population
order by HigestDeathCount desc

-- Break things by continent
Select  continent, 
		MAX(cast(total_deaths as int)) TotalDeathCount
--		population
from CovidProject..CovidDeaths
where continent is not null
-- and continent = 'Europe'
group by continent
order by TotalDeathCount desc


-- Global numbers

Select  
		--date, 
		Sum(new_cases) as total_cases,
		Sum(cast(new_deaths as int)) as new_deaths,
		--total_deaths, 
		CASE
			WHEN Sum(new_cases) = 0 THEN 0  -- Avoid division by zero
			ELSE Sum(COALESCE(cast(new_deaths as int), 0))/Sum(new_cases)*100
		END as percentage_rate
from CovidProject..CovidDeaths
-- where location = 'North Macedonia'
where continent is not null and new_cases is not null and new_deaths is not null
--group by date
order by 1,2



-- Lookig total Pupulation vs Vactination (rolling count)
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    CASE
        WHEN SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) = 0 THEN 0
        ELSE SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date)
    END AS cumulative_vaccinations

FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVactinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3;

 
 -- USE CTE
 with POPvsVAC (Continent, Location, Date, Population, NewVactinations, CumulativeVactinations)
 as
 (
	 SELECT
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		CASE
			WHEN SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) = 0 THEN 0
			ELSE SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date)
		END AS cumulative_vaccinations

	FROM CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVactinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 1, 2, 3
	)
Select *, (CumulativeVactinations/Population)*100 as percentage_vac_rate
from POPvsVAC


-- TEMPORARY TABLE
drop table if exists #PercentPopylationVactinated
create table #PercentPopylationVactinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date date,
	Population numeric,
	NewVactinations numeric,
	CumulativeVactinations numeric
)
insert into #PercentPopylationVactinated
SELECT
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		CASE
			WHEN SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) = 0 THEN 0
			ELSE SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date)
		END AS cumulative_vaccinations

	FROM CovidProject..CovidDeaths dea
	JOIN CovidProject..CovidVactinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	--WHERE dea.continent IS NOT NULL
	--ORDER BY 1, 2, 3

Select *, (CumulativeVactinations/Population)*100 as percentage_vac_rate
from #PercentPopylationVactinated


-- Create view for vizualizations Total Cases vs Total Deaths

CREATE VIEW PercentPopylationVactinated AS
	SELECT
			dea.continent,
			dea.location,
			dea.date,
			dea.population,
			vac.new_vaccinations,
			CASE
				WHEN SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) = 0 THEN 0
				ELSE SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date)
			END AS cumulative_vaccinations

		FROM CovidProject..CovidDeaths dea
		JOIN CovidProject..CovidVactinations vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		--ORDER BY 1, 2, 3

SELECT * 
FROM PercentPopylationVactinated

CREATE VIEW ToatalCasesVSTotalDeaths AS
	Select Location, 
			date, 
			total_cases, 
			total_deaths, convert(float, total_deaths)/convert(float,total_cases)*100 as percentage_rate
	from CovidProject..CovidDeaths
	--where location = 'North Macedonia'


CREATE VIEW HigestInfectonByCountry AS
	Select Location, population, MAX(total_cases) HigestInfectonCount, MAX(convert(float, total_cases)/convert(float,population))*100 as PercentagePopulationInfected
	from CovidProject..CovidDeaths
	--where location = 'North Macedonia'
	group by Location, population
	--order by PercentagePopulationInfected desc

CREATE VIEW HighestDeathRateByPopulation AS
Select  Location, 
		population, 
		MAX(cast(total_deaths as int)) 
		HigestDeathCount, MAX(convert(float, total_deaths)/convert(float,population))*100 as PercentagePopulationDeaths
from CovidProject..CovidDeaths
where continent is not null
group by Location, population


CREATE VIEW TotalDeathByContinent AS
Select  continent, 
		MAX(cast(total_deaths as int)) TotalDeathCount
--		population
from CovidProject..CovidDeaths
where continent is not null
group by continent
