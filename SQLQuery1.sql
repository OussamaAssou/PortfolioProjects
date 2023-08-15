SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

-- Selection des données qu'on utilisera

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2 --trier par l'ordre de la colonne 1, en cas d'égalité par l'ordre de 2

-- Coup d'Oeil sur les total_cases vs total_deaths (% des individus morts parmis les cas positifs pour un pays)
-- Quelle chance auriez-vous eu de mourir si vous aviez attrapé COVID19?

SELECT location, date, total_cases, total_deaths, (CONVERT(float,total_deaths)/CONVERT(float,total_cases))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%france%'
ORDER BY 1,2

-- Coup d'Oeil sur les total_cases vs population
-- Quel % de la population a attrapé le COVID19

SELECT location, date, population, total_cases, (CONVERT(float,total_cases)/CONVERT(float,population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
-- Where location like '%france%'
ORDER BY 1,2

-- Quels pays auraient le plus d'infections par rapport à leur population?

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((CONVERT(float,total_cases)/CONVERT(float,population)))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
-- Where location like '%france%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Pays ayant les plus grands Nombres de Morts par population

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
-- Where location like '%france%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Quant aux continents :

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
-- Where location like '%france%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Retour à la version de résultats compacts.
-- Continents avec le plus grand nombre de morts par population :

SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
-- Where location like '%france%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Par un point de vue de Visualisation sur Tableau, on pourra prendre toutes le requetes ci-dessus en remplaçant location(vague) par continent, ainsi, pourra-t-on
-- faire une sorte de zoom sur chaque continent et voir ce qui se passe au juste. Imaginons avoir différentes couches (continent - pays spécifique de ce continent)

-- Nombres Globaux (échelle mondiale)
-- à la place de total_cases on mettra plutot le cumul de chaque new_case, meme histoire pour les new_deaths 

-- cumul des nombres chaque jour

SELECT date, SUM(new_cases) as TotalNewCases, SUM(CAST(new_deaths AS INT)) as TotalNewDeaths,
    CASE
        WHEN SUM(new_cases) <> 0 THEN (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100
        ELSE NULL
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%france%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- nombres totaux

SELECT SUM(new_cases) as TotalNewCases, SUM(CAST(new_deaths AS INT)) as TotalNewDeaths,
    CASE
        WHEN SUM(new_cases) <> 0 THEN (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100
        ELSE NULL
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%france%'
WHERE continent IS NOT NULL
--GROUP BY date

-- Joindre les deux tables

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Combien de personnes ont été vaccinées dans le monde :

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

-- Améliorer la requete pour retourner un nombre cumulé ( nouvelles vaccinations ) :
-- à chaque nouvelle localisation, on remet à zéro pour calculer un nouveau cumul ( Rolling Count )

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated,
--	(RollingPeopleVaccinated / dea.population) * 100 ( erreur, on vient de créer la table. Impossible de la réutiliser )
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3

-- Utilisation d'une CTE

WITH PopVSVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
AS 
(	
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--	(RollingPeopleVaccinated / dea.population) * 100 ( erreur, on vient de créer la table. Impossible de la réutiliser )
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated / population) * 100 as VaccinPercentage
FROM PopVSVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated -- # pour temporaire
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--	(RollingPeopleVaccinated / dea.population) * 100 ( erreur, on vient de créer la table. Impossible de la réutiliser )
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated / population) * 100 as VaccinPercentage
FROM #PercentPopulationVaccinated

-- Créer une vue pour stocker des données pour visualisation ultérieure

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--	(RollingPeopleVaccinated / dea.population) * 100 ( erreur, on vient de créer la table. Impossible de la réutiliser )
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3

-- On pourra requeter sur cette vue

SELECT *
FROM PercentPopulationVaccinated

-- Enregistrer le tout et importer sur GitHub