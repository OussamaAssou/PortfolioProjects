-- Data Cleaning / Nettoyage de donn�es dans une base de donn�es de logements / immobilier

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- Tache 1 : Standardiser les dates (enlever le temps � la fin puisque cela ne sert � rien) ------------------------------------------------------------------

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

-- On constate que chaque ID de parcelle (PArcelID) est attribu� � une adresse, on partira du principe que si il y'a une adresse manquante, on recherchera le
--Parcel ID, si jamais il y a une entr�e avec le meme Parcel ID qui a une adresse, on la prendra

-- On fera un Self Join

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM DataCleaningHousingSet.dbo.NashvilleHousing a
JOIN DataCleaningHousingSet.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ] -- c'est le meme ParcelID mais dans deux lignes/entr�es diff�rentes
WHERE a.PropertyAddress is NULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) -- si c'est NULL, remplis avec l'@ de b
FROM DataCleaningHousingSet.dbo.NashvilleHousing a
JOIN DataCleaningHousingSet.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ] -- c'est le meme ParcelID mais dans deux lignes/entr�es diff�rentes
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

-- Tache 3 : S�parer les adresses en adresse, ville, �tat -------------------------------------------------------------------------------------------------

SELECT PropertyAddress
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- On constate que l'adresse est compos�e de 2 parties, s�par�es par une virgule

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- On se retrouve avec un probl�me : les adresses se terminent avec une virgule

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
FROM DataCleaningHousingSet.dbo.NashvilleHousing

-- C'est bon pour la premi�re partie

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

-- Voyons une 2�me m�thode, on l'appliquera sur les @ des propri�taires

SELECT OwnerAddress
FROM DataCleaningHousingSet.dbo.NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), -- Cette fonction n�cessite des points non pas des virgules
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), -- parsename compte � l'envers
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

-- Tache 4 : Changer les Y et N � Yes et No dans la colonne 'Sold as Vacant' (non meubl�) ------------------------------------------------------------------

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

-- Maintenant qu'on les a point�, on les supprime

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

-- Tache 6 : Supprimer les colonnes non utilis�es (anciennes colonnes adresses) ----------------------------------------------------------------------------

SELECT *
FROM DataCleaningHousingSet.dbo.NashvilleHousing

ALTER TABLE DataCleaningHousingSet.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE DataCleaningHousingSet.dbo.NashvilleHousing
DROP COLUMN SaleDate