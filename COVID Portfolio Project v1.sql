Select *
From PortfolioProject..CovidDeaths$
Order by 3,4;

Select *
From PortfolioProject..CovidVaccinations$
Order by 3,4;

-- Total Deaths vs Total Cases 

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths$
where location like '%india%'
order by 1,2;

-- Total Cases vs Population

Select location, date, total_cases, population, (total_cases/population)*100 as Case_Percentage
From PortfolioProject..CovidDeaths$
--where location like '%india%'
order by 1,2;

-- Countries with highest infection rate

Select location, max(total_cases) as Highest_Case_Count, population, (max(total_cases)/population)*100 as Highest_Population_PercentInfected
From PortfolioProject..CovidDeaths$ 
Group by location, population
order by Highest_Population_PercentInfected desc;

-- Countries with highest death percentage per population

Select location, max(cast(total_deaths as int)) as Highest_DeathCount, max(total_deaths/population)*100 as Highest_DeathPercent
From PortfolioProject..CovidDeaths$ 
where continent is not null 
Group by location
order by Highest_DeathCount desc;

-- GROUPING BY CONTINENT

Select continent, max(cast(total_deaths as int)) as Highest_DeathCount, max(total_deaths/population)*100 as Highest_DeathPercent
From PortfolioProject..CovidDeaths$ 
where continent is not null 
Group by continent
order by Highest_DeathCount desc;

--GLOBAL Data based on Date

Select date, sum(new_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as Percentage
From PortfolioProject..CovidDeaths$
where continent is not null	
group by date
order by date;

Select sum(new_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as Percentage
From PortfolioProject..CovidDeaths$
where continent is not null

-- Vaccination Data

Select * from PortfolioProject..CovidVaccinations$ order by location

Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by death.location order by death.location, death.date) as Total_People_Vaccinated
from PortfolioProject..CovidDeaths$ death 
join PortfolioProject..CovidVaccinations$ vac
 on death.location = vac.location
   and  death.date = vac.date
 where death.continent is not null
 order by 2,3

 --Perform calculated field for Total_People_Vaccinated/population we can do it in same table. 
 --for that temperorary table have to be created or CTE

 with Vac_vs_Pop as
 (
 Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by death.location order by death.location, death.date) as Total_People_Vaccinated
from PortfolioProject..CovidDeaths$ death 
join PortfolioProject..CovidVaccinations$ vac
 on death.location = vac.location
   and  death.date = vac.date
 where death.continent is not null
 --order by 2,3
 )
Select *, (Total_People_Vaccinated/population)*100 as Percentage_Vaccinated
from Vac_vs_Pop
order by 2,3

--Also we can create temp Table using
--CREATE TABLE #temp_table (column_list) INSERT VALUES ()

--Create view to store data for later visualisation

Create view Total_Population_Vaccinated as 
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by death.location order by death.location, death.date) as Total_People_Vaccinated
from PortfolioProject..CovidDeaths$ death 
join PortfolioProject..CovidVaccinations$ vac
 on death.location = vac.location
   and  death.date = vac.date
 where death.continent is not null
--order by 2,3

Select *
from Total_Population_Vaccinated