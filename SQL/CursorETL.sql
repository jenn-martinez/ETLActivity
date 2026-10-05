DECLARE @SourceRowID AS NVARCHAR(50)
DECLARE @DocumentType AS NVARCHAR(50)
DECLARE @DocumentNumber AS NVARCHAR(50)
DECLARE @FirstName AS NVARCHAR(50)
DECLARE @MiddleName AS NVARCHAR(50)
DECLARE @LastName AS NVARCHAR(50)
DECLARE @SecondLastName AS NVARCHAR(50)
DECLARE @MonthlyIncome AS NVARCHAR(50)
DECLARE @MonthlyExpense AS NVARCHAR(50)
DECLARE @Income AS DECIMAL(18,2)
DECLARE @Expense AS DECIMAL(18,2)
DECLARE @MonthlyBalance AS DECIMAL(18,2)
DECLARE @Reason AS NVARCHAR(1000)
DECLARE @BirthDate AS NVARCHAR(50)
DECLARE @ReportedAge AS TINYINT
DECLARE @Sex AS NVARCHAR(50)
DECLARE @MaritalStatus AS NVARCHAR(50)
DECLARE @Email AS NVARCHAR(50)
DECLARE @Phone AS NVARCHAR(50)
DECLARE @DepartmentCode AS NVARCHAR(50)
DECLARE @DepartmentName AS NVARCHAR(50)
DECLARE @MunicipalityCode AS NVARCHAR(50)
DECLARE @MunicipalityName AS NVARCHAR(50)
DECLARE @Zone AS NVARCHAR(50)
DECLARE @Address AS NVARCHAR(50)
DECLARE @HousingType AS NVARCHAR(50)
DECLARE @SocioeconomicStratum AS NVARCHAR(50)
DECLARE @EducationLevel AS NVARCHAR(50)
DECLARE @EmploymentStatus AS NVARCHAR(50)
DECLARE @OccupationCode AS NVARCHAR(50)
DECLARE @OccupationName AS NVARCHAR(50)
DECLARE @EmployerName AS NVARCHAR(50)
DECLARE @ContractType AS NVARCHAR(50)
DECLARE @EmploymentStartDate AS DATE
DECLARE @Dependents AS NVARCHAR(50)
DECLARE @HouseholdSize AS TINYINT
DECLARE @HealthRegime AS NVARCHAR(50)
DECLARE @Disability AS NVARCHAR(50)
DECLARE @SurveyDate AS NVARCHAR(50)
DECLARE @UpdatedAt AS DATETIME2(7)
DECLARE @SourceChannel AS NVARCHAR(50)

DECLARE CursorPersonas CURSOR FOR 
	SELECT SourceRowId
      ,DocumentType,DocumentNumber,FirstName,MiddleName,LastName,SecondLastName
      ,BirthDate,ReportedAge,Sex,MaritalStatus,Email,Phone,DepartmentCode
      ,DepartmentName,MunicipalityCode,MunicipalityName
      ,[Zone],[Address],[HousingType],[SocioeconomicStratum]
      ,[EducationLevel],[EmploymentStatus],[OccupationCode],[OccupationName]
      ,[EmployerName],[ContractType],[EmploymentStartDate],[MonthlyIncome]
      ,[MonthlyExpenses],[Dependents],[HouseholdSize],[HealthRegime]
      ,[Disability],[SurveyDate],[UpdatedAt],[SourceChannel]
    FROM StagingETL
	WHERE SourceRowId BETWEEN 1 AND 100 
	OPEN CursorPersonas
		FETCH NEXT FROM CursorPersonas INTO @SourceRowID,@DocumentType,@DocumentNumber, @FirstName,@MiddleName,
        @LastName,@SecondLastName,@BirthDate,@ReportedAge,@Sex,@MaritalStatus,@Email,@Phone,@DepartmentCode,
        @DepartmentName,@MunicipalityCode,@MunicipalityName,@Zone,@Address,@HousingType,@SocioeconomicStratum,
        @EducationLevel,@EmploymentStatus,@OccupationCode, @OccupationName,@EmployerName,@ContractType,
        @EmploymentStartDate,@MonthlyIncome,@MonthlyExpense,@Dependents,@HouseholdSize,@HealthRegime,
        @Disability,@SurveyDate,@UpdatedAt,@SourceChannel
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Reason = ''
				SET @DocumentType = UPPER(TRIM(@DocumentType))
				SET @FirstName = TRIM(UPPER(LEFT(@FirstName, 1) + LOWER(SUBSTRING(@FirstName, 2, LEN(@FirstName)))))
				SET @MiddleName= TRIM(UPPER(LEFT(@MiddleName, 1) + LOWER(SUBSTRING(@MiddleName, 2, LEN(@MiddleName)))))
				SET @LastName= TRIM(UPPER(LEFT(@LastName, 1) + LOWER(SUBSTRING(@LastName, 2, LEN(@LastName)))))
				SET @SecondLastName= TRIM(UPPER(LEFT(@SecondLastName, 1) + LOWER(SUBSTRING(@SecondLastName, 2, LEN(@SecondLastName)))))

				IF @DocumentNumber IS NULL
					BEGIN
						SET @Reason = @Reason + 'Falta el numero de documento; '
					END

				IF @FirstName IS NULL
					BEGIN
						SET @Reason = @Reason + 'Falta el primer nombre; '
					END

				IF @LastName IS NULL
					BEGIN
						SET @Reason = @Reason + 'Falta el primer apellido; '
					END

				SET @MonthlyIncome = TRIM(REPLACE(REPLACE(REPLACE(@MonthlyIncome, '$', ''), '.', ''),',','.'))
				SET @MonthlyExpense = TRIM(REPLACE(REPLACE(REPLACE(@MonthlyExpense, '$', ''), '.', ''),',','.'))
				SET @Income = TRY_CONVERT(DECIMAL(18,2), @MonthlyIncome)
				SET @Expense = TRY_CONVERT(DECIMAL(18,2), @MonthlyExpense)

				IF @MonthlyIncome IS NULL
					BEGIN
						SET @Reason = @Reason + 'Falta el valor del ingreso mensual; '
					END

				IF @Income < 0
					BEGIN
						SET @Reason = @Reason + 'EL valor del ingreso mensual es negativo; '
					END

				IF @Income IS NULL
					BEGIN
						SET @Reason = @Reason + 'EL valor del ingreso mensual no es numerico; '
					END

				IF @MonthlyExpense IS NULL
					BEGIN
						SET @Reason = @Reason + 'Falta el valor del gasto mensual; '
					END

				IF @Expense < 0
					BEGIN
						SET @Reason = @Reason + 'El valor del gasto mensual es negativo; '
					END

				IF @Expense IS NULL
					BEGIN
						SET @Reason = @Reason + 'El valor del gasto mensual no es numerico; '
					END

				IF @Income IS NOT NULL AND @Expense IS NOT NULL
					BEGIN
						SET @MonthlyBalance = @Income - @Expense
					END
				ELSE
					BEGIN
						SET @MonthlyBalance = NULL
					END
				

				IF @Reason <> ''
					BEGIN
						INSERT INTO RejectedPeople
                            (SourceRowId,DocumentType,DocumentNumber,FirstName,MiddleName,LastName,SecondLastName
                              ,BirthDate,ReportedAge,Sex,MaritalStatus,Email,Phone,DepartmentCode
                              ,DepartmentName,MunicipalityCode,MunicipalityName
                              ,[Zone],[Address],[HousingType],[SocioeconomicStratum]
                              ,[EducationLevel],[EmploymentStatus],[OccupationCode],[OccupationName]
                              ,[EmployerName],[ContractType],[EmploymentStartDate],[MonthlyIncome]
                              ,[MonthlyExpenses],[Dependents],[HouseholdSize],[HealthRegime]
                              ,[Disability],[SurveyDate],[UpdatedAt],[SourceChannel],[Reason])
                        VALUES
                            (@SourceRowID, @DocumentType, @DocumentNumber, @FirstName, @MiddleName, @LastName, @SecondLastName,
                             @BirthDate, @ReportedAge, @Sex, @MaritalStatus, @Email, @Phone, @DepartmentCode,
                             @DepartmentName, @MunicipalityCode, @MunicipalityName, @Zone, @Address, @HousingType,
                             @SocioeconomicStratum, @EducationLevel, @EmploymentStatus, @OccupationCode,
                             @OccupationName, @EmployerName, @ContractType, @EmploymentStartDate, @MonthlyIncome,
                             @MonthlyExpense, @Dependents, @HouseholdSize, @HealthRegime, @Disability,
                             @SurveyDate, @UpdatedAt, @SourceChannel, @Reason)
					END
				ELSE
					BEGIN
					INSERT INTO ValidPeople
                            (SourceRowId,DocumentType,DocumentNumber,FirstName,MiddleName,LastName,SecondLastName
                              ,BirthDate,ReportedAge,Sex,MaritalStatus,Email,Phone,DepartmentCode
                              ,DepartmentName,MunicipalityCode,MunicipalityName
                              ,[Zone],[Address],[HousingType],[SocioeconomicStratum]
                              ,[EducationLevel],[EmploymentStatus],[OccupationCode],[OccupationName]
                              ,[EmployerName],[ContractType],[EmploymentStartDate],[MonthlyIncome]
                              ,[MonthlyExpenses],[Dependents],[HouseholdSize],[HealthRegime]
                              ,[Disability],[SurveyDate],[UpdatedAt],[SourceChannel],[MonthlyBalance])
                        VALUES
                            (@SourceRowID, @DocumentType, @DocumentNumber, @FirstName, @MiddleName, @LastName, @SecondLastName,
                             @BirthDate, @ReportedAge, @Sex, @MaritalStatus, @Email, @Phone, @DepartmentCode,
                             @DepartmentName, @MunicipalityCode, @MunicipalityName, @Zone, @Address, @HousingType,
                             @SocioeconomicStratum, @EducationLevel, @EmploymentStatus, @OccupationCode,
                             @OccupationName, @EmployerName, @ContractType, @EmploymentStartDate, @MonthlyIncome,
                             @MonthlyExpense, @Dependents, @HouseholdSize, @HealthRegime, @Disability,
                             @SurveyDate, @UpdatedAt, @SourceChannel, @MonthlyBalance)
                    END

				FETCH NEXT FROM CursorPersonas INTO @SourceRowID,@DocumentType,@DocumentNumber, @FirstName,@MiddleName,
                @LastName,@SecondLastName,@BirthDate,@ReportedAge,@Sex,@MaritalStatus,@Email,@Phone,@DepartmentCode,
                @DepartmentName,@MunicipalityCode,@MunicipalityName,@Zone,@Address,@HousingType,@SocioeconomicStratum,
                @EducationLevel,@EmploymentStatus,@OccupationCode, @OccupationName,@EmployerName,@ContractType,
                @EmploymentStartDate,@MonthlyIncome,@MonthlyExpense,@Dependents,@HouseholdSize,@HealthRegime,
                @Disability,@SurveyDate,@UpdatedAt,@SourceChannel
			END
	CLOSE  CursorPersonas
DEALLOCATE CursorPersonas