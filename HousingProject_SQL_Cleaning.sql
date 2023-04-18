-- Cleaning Data Queries

Select *
From HousingProject..NashvilleHousing


-- Standardize Date Format 
Update NashvilleHousing
Set SaleDate = Convert(Date, SaleDate)

Alter Table NashvilleHousing
Add SaleDateFormatted Date;

Update NashvilleHousing
Set SaleDateFormatted = Convert(Date, SaleDate)

Select SaleDateFormatted
From HousingProject..NashvilleHousing

----------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data, Filling in Null Values in PropertyAddress
Select PropertyAddress
From HousingProject..NashvilleHousing

Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
From HousingProject..NashvilleHousing A
Join HousingProject..NashvilleHousing B
	On A.ParcelID = B.ParcelID
	And A.[UniqueID ] <> B.[UniqueID ]
Where A.PropertyAddress is null 

Update A
Set PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
From HousingProject..NashvilleHousing A
Join HousingProject..NashvilleHousing B
	On A.ParcelID = B.ParcelID
	And A.[UniqueID ] <> B.[UniqueID ]
Where A.PropertyAddress is null 

----------------------------------------------------------------------------------------------------------------

-- Breaking Address into (Address, City, State) Columns
-- There is a common delimiter for all the addresses available (",")
Select PropertyAddress
From HousingProject..NashvilleHousing


Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) As Address, -- -1 is used to delete the "," from the end of each address
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) As Address -- include the substring after the comma in the address (In this case, the city)
From HousingProject..NashvilleHousing

-- Now, Update existing table
Alter Table NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)


Alter Table NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

----------------------------------------------------------------------------------------------------------------

-- Now, Do the same thing as before but for owner address
-- Using ParseName Method this time!
-- ParseName only looks for periods. Thus, change the commas in the address to periods then move from there
Select
PARSENAME(Replace(OwnerAddress, ',', '.'), 3),
PARSENAME(Replace(OwnerAddress, ',', '.'), 2),
PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
From HousingProject..NashvilleHousing

-- Update the table
Alter Table NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)


Alter Table NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)


Alter Table NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

----------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "SoldAsVacant" Column
Select Distinct(SoldAsVacant), Count(SoldAsVacant)	
From HousingProject..NashvilleHousing
Group by SoldAsVacant
Order by 2


Select SoldAsVacant
, Case When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant 
	   End
From HousingProject..NashvilleHousing


-- Update existing table
Update NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant 
	   End

----------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- Row_Num column would be 1 if the row is unique and 2 or higher if the rows are repeated 
With RowNumCTE As(
Select *, 
ROW_NUMBER() Over (Partition By ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
				   Order By UniqueID) Row_Num
From HousingProject..NashvilleHousing
--Order By ParcelID
)
Delete -- Removing duplicates rows with a Row_Num value greater than 1
From RowNumCTE
where Row_Num > 1
-- NOTE: We are removing rows from raw data for practice purposes only. This practice should be considered in real life situation

----------------------------------------------------------------------------------------------------------------

-- Finally, Delete Unneeded Columns

Alter Table HousingProject..NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress

Alter Table HousingProject..NashvilleHousing
Drop Column SaleDate

-- Check The Final Result Table
Select * 
From HousingProject..NashvilleHousing
