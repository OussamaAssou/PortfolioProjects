-- Data Cleaning / Nettoyage de données dans une base de données de logements / immobilier

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- Tache 1 : Standardiser les dates (enlever le temps à la fin puisque cela ne sert à rien) ------------------------------------------------------------------

SELECT SaleDate, CONVERT(Date, SaleDate) AS NewSaleDate
FROM DataCleaningHousingSet.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate) -- Peut etre que cela ne marche pas, essayons autre chose

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date; -- ajout d'une nouvelle colonne dans la table

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- Tache 2 : Remplir les champs d'adresses qui sont vides -----------------------------------------------------------------------------------------------------

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing
WHERE PropertyAddress is NULL

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing
-- WHERE PropertyAddress is NULL
ORDER BY ParcelID

-- On constate que chaque ID de parcelle (PArcelID) est attribué à une adresse, on partira du principe que si il y'a une adresse manquante, on recherchera le
--Parcel ID, si jamais il y a une entrée avec le meme Parcel ID qui a une adresse, on la prendra

-- On fera un Self Join

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM DataCleaningHousingSet.dbo.NashvilleHousing a
JOIN DataCleaningHousingSet.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ] -- c'est le meme ParcelID mais dans deux lignes/entrées différentes
WHERE a.PropertyAddress is NULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) -- si c'est NULL, remplis avec l'@ de b
FROM DataCleaningHousingSet.dbo.NashvilleHousing a
JOIN DataCleaningHousingSet.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ] -- c'est le meme ParcelID mais dans deux lignes/entrées différentes
WHERE a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningHousingSet.dbo.NashvilleHousing a
JOIN DataCleaningHousingSet.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

SELECT PropertyAddress
FROM DataCleaningHousingSet.dbo.NashvilleHousing
WHERE PropertyAddress is NULL

-- Tache 3 : Séparer les adresses en adresse, ville, état -------------------------------------------------------------------------------------------------

SELECT PropertyAddress
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- On constate que l'adresse est composée de 2 parties, séparées par une virgule

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- On se retrouve avec un problème : les adresses se terminent avec une virgule

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- C'est bon pour la première partie

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM DataCleaningHousingSet.dbo.NashvilleHousing

USE DataCleaningHousingSet
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255); -- ajout d'une nouvelle colonne dans la table

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255); -- ajout d'une nouvelle colonne dans la table

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- Voyons une 2ème méthode, on l'appliquera sur les @ des propriétaires

SELECT OwnerAddress
FROM DataCleaningHousingSet.dbo.NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), -- Cette fonction nécessite des points non pas des virgules
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), -- parsename compte à l'envers
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- Action

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255); -- ajout d'une nouvelle colonne dans la table

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255); -- ajout d'une nouvelle colonne dans la table

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255); -- ajout d'une nouvelle colonne dans la table

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- Tache 4 : Changer les Y et N à Yes et No dans la colonne 'Sold as Vacant' (non meublé) ------------------------------------------------------------------

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM DataCleaningHousingSet.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM DataCleaningHousingSet.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM DataCleaningHousingSet.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Tache 5 : Supprimer les doublures -------------------------------------------------------------------------------------------------------------------

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing

WITH RowNumCTE AS (

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, 
PropertyAddress, 
SalePrice,
SaleDate,
LegalReference
ORDER BY UniqueID ) row_num
FROM DataCleaningHousingSet.dbo.NashvilleHousing )

SELECT *
From RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Maintenant qu'on les a pointé, on les supprime

WITH RowNumCTE AS (

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, 
PropertyAddress, 
SalePrice,
SaleDate,
LegalReference
ORDER BY UniqueID ) row_num
FROM DataCleaningHousingSet.dbo.NashvilleHousing )

DELETE
From RowNumCTE
WHERE row_num > 1

-- juste pour etre surs

WITH RowNumCTE AS (

SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID, 
PropertyAddress, 
SalePrice,
SaleDate,
LegalReference
ORDER BY UniqueID ) row_num
FROM DataCleaningHousingSet.dbo.NashvilleHousing )

SELECT *
From RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Tache 6 : Supprimer les colonnes non utilisées (anciennes colonnes adresses) ----------------------------------------------------------------------------

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing

ALTER TABLE DataCleaningHousingSet.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE DataCleaningHousingSet.dbo.NashvilleHousing
DROP COLUMN SaleDate