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
DECLARE @TotalProcesados INT = 0
DECLARE @TotalAceptados INT = 0
DECLARE @TotalRechazados INT = 0

DECLARE CursorPersonas CURSOR FOR 
    SELECT SourceRowId, DocumentType, DocumentNumber, FirstName, MiddleName, LastName, SecondLastName,
           BirthDate, ReportedAge, Sex, MaritalStatus, Email, Phone, DepartmentCode,
           DepartmentName, MunicipalityCode, MunicipalityName, [Zone], [Address], [HousingType], [SocioeconomicStratum],
           [EducationLevel], [EmploymentStatus], [OccupationCode], [OccupationName],
           [EmployerName], [ContractType], [EmploymentStartDate], [MonthlyIncome],
           [MonthlyExpenses], [Dependents], [HouseholdSize], [HealthRegime],
           [Disability], [SurveyDate], [UpdatedAt], [SourceChannel]
    FROM StagingETL
    WHERE SourceRowId BETWEEN 1 AND 100

    OPEN CursorPersonas

        FETCH NEXT FROM CursorPersonas INTO 
            @SourceRowID, @DocumentType, @DocumentNumber, @FirstName, @MiddleName,
            @LastName, @SecondLastName, @BirthDate, @ReportedAge, @Sex, @MaritalStatus, @Email, @Phone, @DepartmentCode,
            @DepartmentName, @MunicipalityCode, @MunicipalityName, @Zone, @Address, @HousingType, @SocioeconomicStratum,
            @EducationLevel, @EmploymentStatus, @OccupationCode, @OccupationName, @EmployerName, @ContractType,
            @EmploymentStartDate, @MonthlyIncome, @MonthlyExpense, @Dependents, @HouseholdSize, @HealthRegime,
            @Disability, @SurveyDate, @UpdatedAt, @SourceChannel

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @TotalProcesados = @TotalProcesados + 1
            SET @Reason = ''

            SET @DocumentType = UPPER(TRIM(@DocumentType))
            SET @DocumentNumber = TRIM(@DocumentNumber)

            IF @FirstName IS NOT NULL AND TRIM(@FirstName) <> ''
                SET @FirstName = UPPER(LEFT(TRIM(@FirstName), 1)) + LOWER(SUBSTRING(TRIM(@FirstName), 2, LEN(TRIM(@FirstName))))
            ELSE
                SET @FirstName = NULL

            IF @MiddleName IS NOT NULL AND TRIM(@MiddleName) <> ''
                SET @MiddleName = UPPER(LEFT(TRIM(@MiddleName), 1)) + LOWER(SUBSTRING(TRIM(@MiddleName), 2, LEN(TRIM(@MiddleName))))
            ELSE
                SET @MiddleName = NULL

            IF @LastName IS NOT NULL AND TRIM(@LastName) <> ''
                SET @LastName = UPPER(LEFT(TRIM(@LastName), 1)) + LOWER(SUBSTRING(TRIM(@LastName), 2, LEN(TRIM(@LastName))))
            ELSE
                SET @LastName = NULL

            IF @SecondLastName IS NOT NULL AND TRIM(@SecondLastName) <> ''
                SET @SecondLastName = UPPER(LEFT(TRIM(@SecondLastName), 1)) + LOWER(SUBSTRING(TRIM(@SecondLastName), 2, LEN(TRIM(@SecondLastName))))
            ELSE
                SET @SecondLastName = NULL

            IF @DocumentNumber IS NULL OR UPPER(@DocumentNumber) = 'SIN-DATO' OR TRIM(@DocumentNumber) = ''
                SET @Reason = @Reason + 'Falta el número de documento o es inválido; '

            IF @FirstName IS NULL
                SET @Reason = @Reason + 'Falta el primer nombre; '

            IF @LastName IS NULL
                SET @Reason = @Reason + 'Falta el primer apellido; '

            IF @MonthlyIncome IS NOT NULL AND TRIM(@MonthlyIncome) <> ''
                BEGIN
                    DECLARE @CleanIncome NVARCHAR(50)
                    SET @CleanIncome = REPLACE(REPLACE(REPLACE(TRIM(@MonthlyIncome), '$', ''), ' ', ''), '.', '')
                    SET @CleanIncome = REPLACE(@CleanIncome, ',', '.')
        
                    SET @Income = TRY_CONVERT(DECIMAL(18,2), @CleanIncome)

                    IF @Income IS NULL
                        SET @Reason = @Reason + 'El valor del ingreso mensual no es numérico; '
                    ELSE IF @Income < 0
                        SET @Reason = @Reason + 'El valor del ingreso mensual es negativo; '
                END
            ELSE
                BEGIN
                    SET @Income = NULL
                    SET @Reason = @Reason + 'Falta el valor del ingreso mensual; '
                END

            IF @MonthlyExpense IS NOT NULL AND TRIM(@MonthlyExpense) <> ''
                BEGIN
                    DECLARE @CleanExpense NVARCHAR(50)
                    SET @CleanExpense = REPLACE(REPLACE(REPLACE(TRIM(@MonthlyExpense), '$', ''), ' ', ''), '.', '')
                    SET @CleanExpense = REPLACE(@CleanExpense, ',', '.')
        
                    SET @Expense = TRY_CONVERT(DECIMAL(18,2), @CleanExpense)

                    IF @Expense IS NULL
                        SET @Reason = @Reason + 'El valor del gasto mensual no es numérico; '
                    ELSE IF @Expense < 0
                        SET @Reason = @Reason + 'El valor del gasto mensual es negativo; '
                END
            ELSE
                BEGIN
                    SET @Expense = NULL
                    SET @Reason = @Reason + 'Falta el valor del gasto mensual; '
                END

            IF @Income IS NOT NULL AND @Expense IS NOT NULL
                SET @MonthlyBalance = @Income - @Expense
            ELSE
                SET @MonthlyBalance = NULL

            IF @Reason <> ''
            BEGIN
                SET @TotalRechazados = @TotalRechazados + 1
                INSERT INTO RejectedPeople
                    (SourceRowId, DocumentType, DocumentNumber, FirstName, MiddleName, LastName, SecondLastName,
                     BirthDate, ReportedAge, Sex, MaritalStatus, Email, Phone, DepartmentCode,
                     DepartmentName, MunicipalityCode, MunicipalityName, [Zone], [Address], [HousingType], [SocioeconomicStratum],
                     [EducationLevel], [EmploymentStatus], [OccupationCode], [OccupationName],
                     [EmployerName], [ContractType], [EmploymentStartDate], [MonthlyIncome],
                     [MonthlyExpenses], [Dependents], [HouseholdSize], [HealthRegime],
                     [Disability], [SurveyDate], [UpdatedAt], [SourceChannel], [Reason])
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
                SET @TotalAceptados = @TotalAceptados + 1
                INSERT INTO ValidPeople
                    (SourceRowId, DocumentType, DocumentNumber, FirstName, MiddleName, LastName, SecondLastName,
                     BirthDate, ReportedAge, Sex, MaritalStatus, Email, Phone, DepartmentCode,
                     DepartmentName, MunicipalityCode, MunicipalityName, [Zone], [Address], [HousingType], [SocioeconomicStratum],
                     [EducationLevel], [EmploymentStatus], [OccupationCode], [OccupationName],
                     [EmployerName], [ContractType], [EmploymentStartDate], [MonthlyIncome],
                     [MonthlyExpenses], [Dependents], [HouseholdSize], [HealthRegime],
                     [Disability], [SurveyDate], [UpdatedAt], [SourceChannel], [MonthlyBalance])
                VALUES
                    (@SourceRowID, @DocumentType, @DocumentNumber, @FirstName, @MiddleName, @LastName, @SecondLastName,
                     @BirthDate, @ReportedAge, @Sex, @MaritalStatus, @Email, @Phone, @DepartmentCode,
                     @DepartmentName, @MunicipalityCode, @MunicipalityName, @Zone, @Address, @HousingType,
                     @SocioeconomicStratum, @EducationLevel, @EmploymentStatus, @OccupationCode,
                     @OccupationName, @EmployerName, @ContractType, @EmploymentStartDate, @MonthlyIncome,
                     @MonthlyExpense, @Dependents, @HouseholdSize, @HealthRegime, @Disability,
                     @SurveyDate, @UpdatedAt, @SourceChannel, @MonthlyBalance)
            END

            FETCH NEXT FROM CursorPersonas INTO 
                @SourceRowID, @DocumentType, @DocumentNumber, @FirstName, @MiddleName,
                @LastName, @SecondLastName, @BirthDate, @ReportedAge, @Sex, @MaritalStatus, @Email, @Phone, @DepartmentCode,
                @DepartmentName, @MunicipalityCode, @MunicipalityName, @Zone, @Address, @HousingType, @SocioeconomicStratum,
                @EducationLevel, @EmploymentStatus, @OccupationCode, @OccupationName, @EmployerName, @ContractType,
                @EmploymentStartDate, @MonthlyIncome, @MonthlyExpense, @Dependents, @HouseholdSize, @HealthRegime,
                @Disability, @SurveyDate, @UpdatedAt, @SourceChannel
        END

    CLOSE CursorPersonas
    DEALLOCATE CursorPersonas

SELECT 
    @TotalProcesados AS [Registros Procesados],
    @TotalAceptados AS [Registros Aceptados],
    @TotalRechazados AS [Registros Rechazados]