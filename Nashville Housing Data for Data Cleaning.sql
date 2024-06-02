-- Create table
CREATE TABLE public.nashville_housing
(UniqueID varchar(100),
 ParcelID varchar(100),
 LandUse varchar(100),
 PropertyAddress varchar(100),
 SaleDate date,
 SalePrice varchar(100),
 LegalReference varchar(100),
 SoldAsVacant varchar(100),
 OwnerName varchar(100),
 OwnerAddress varchar(100),
 Acreage float,
 TaxDistrict varchar(100),
 LandValue int,
 BuildingValue int,
 TotalValue int,
 YearBuilt int,
 Bedrooms int,
 FullBath int,
 HalfBath int,
 PRIMARY KEY(UniqueID)
);

ALTER TABLE IF EXISTS public.nashville_housing
    OWNER to postgres;



-- To show data cleaning, I had to turn SalePrice from a float or int into a varchar, so I would drop the table to re-enter
DROP TABLE public.nashville_housing;



-- Populate property address
SELECT *
FROM nashville_housing
--WHERE propertyaddress IS NULL
ORDER BY parcelid;

-- Self joining to check NULL values
SELECT a.uniqueID, a.propertyaddress, b.uniqueID, b.propertyaddress, COALESCE(a.propertyaddress, b.propertyaddress)
FROM nashville_housing a
JOIN nashville_housing b ON a.parcelid = b.parcelid
	AND a.uniqueID <> b.uniqueID
WHERE a.propertyaddress IS NULL;

-- Updated property addresses
UPDATE nashville_housing a
SET propertyaddress = COALESCE(a.propertyaddress, b.propertyaddress)
FROM nashville_housing b
WHERE a.parcelid = b.parcelid
    AND a.uniqueID <> b.uniqueID
    AND a.propertyaddress IS NULL;



-- Breaking down Address into Individual Columns (Address, City, State) with substrings
-- Confirming placements
SELECT 
    SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1) AS Address,
    SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 1 FOR LENGTH(propertyaddress)) AS Rest_of_Address
FROM 
    nashville_housing;

-- Altering tables
ALTER TABLE nashville_housing
ADD property_split_address varchar(255);

UPDATE nashville_housing
SET property_split_address = SUBSTRING(propertyaddress FROM 1 FOR POSITION(',' IN propertyaddress) - 1);


ALTER TABLE nashville_housing
ADD property_split_city varchar(255);

UPDATE nashville_housing
SET property_split_city = SUBSTRING(propertyaddress FROM POSITION(',' IN propertyaddress) + 1 FOR LENGTH(propertyaddress));



-- Breaking down Address into Individual Columns (Address, City, State) with split parts
SELECT SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 1),
	SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 2),
	SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 3)
FROM nashville_housing;

-- Altering tables
ALTER TABLE nashville_housing
ADD owner_split_address varchar(255);

UPDATE nashville_housing
SET owner_split_address = SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 1);

ALTER TABLE nashville_housing
ADD owner_split_city varchar(255);

UPDATE nashville_housing
SET owner_split_city = SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 2);

ALTER TABLE nashville_housing
ADD owner_split_state varchar(255);

UPDATE nashville_housing
SET owner_split_state = SPLIT_PART(REPLACE(owneraddress, ',', '.'), '.', 3);



-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM nashville_housing
GROUP BY soldasvacant
ORDER BY 2;

-- Using CASE statement to check change
SELECT soldasvacant, 
	CASE WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant
		END
FROM nashville_housing;

-- Updating table
UPDATE nashville_housing
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant
		END;



-- Removing duplicates and unused columns
WITH rownumcte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Parcelid, propertyaddress, saleprice, saledate, legalreference
                              ORDER BY uniqueid) AS row_num
    FROM nashville_housing
)
DELETE FROM nashville_housing
WHERE (Parcelid, propertyaddress, saleprice, saledate, legalreference, uniqueid) IN (
    SELECT Parcelid, propertyaddress, saleprice, saledate, legalreference, uniqueid
    FROM rownumcte
    WHERE row_num > 1
);



-- Delete unused columns
ALTER TABLE nashville_housing
DROP COLUMN owneraddress, 
DROP COLUMN taxdistrict, 
DROP COLUMN propertyaddress,
DROP COLUMN saledate