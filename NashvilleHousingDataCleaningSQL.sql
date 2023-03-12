/*Cleaning data
Key: TC = table check, SC = strategy check 
*/

--standardize date format
SELECT saleDateConverted, CONVERT(Date, SaleDate) --SC
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ADD saleDateConverted DATE;

UPDATE NashvilleHousing
SET saleDateConverted = CONVERT(Date,SaleDate)

--fill property address data
SELECT * --TC
FROM NashvilleHousing
WHERE PropertyAddress is null

SELECT nash.ParcelID, nash.PropertyAddress, hous.ParcelID, hous.PropertyAddress, ISNULL(nash.PropertyAddress,hous.PropertyAddress) --SC
FROM NashvilleHousing nash
JOIN NashvilleHousing hous
	ON nash.ParcelID = hous.ParcelID 
	AND nash.[UniqueID ] <> hous.[UniqueID ]
WHERE nash.PropertyAddress is null

UPDATE nash
SET PropertyAddress = ISNULL(nash.PropertyAddress,hous.PropertyAddress)
FROM NashvilleHousing nash
JOIN NashvilleHousing hous
	ON nash.ParcelID = hous.ParcelID 
	AND nash.[UniqueID ] <> hous.[UniqueID ]
WHERE nash.PropertyAddress is null

--break up addresses
SELECT * --TC
FROM NashvilleHousing


SELECT --SC
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET  PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD  PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT --SC
PARSENAME(REPLACE(OwnerAddress, ',', '.'),	3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),	2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),	1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET  OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),	3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity  Nvarchar(255);

UPDATE NashvilleHousing
SET  OwnerSplitCity  = PARSENAME(REPLACE(OwnerAddress, ',', '.'),	2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState  Nvarchar(255);

UPDATE NashvilleHousing
SET  OwnerSplitState  = PARSENAME(REPLACE(OwnerAddress, ',', '.'),	1)


--Make sold as vacant column consistent

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant) --TC
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant, --SC
CASE 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =
CASE 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
END

--remove duplicates

WITH RowNumCTE AS(
SELECT *, 
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			 PropertyAddress,
 			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY
				 UniqueID
				 ) row_num

FROM NashvilleHousing
)

select * --TC, used DELETE to remove duplicate rows
FROM RowNumCTE
WHERE row_num > 1

--deleting unused columns

SELECT * --TC
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate
