
/****** Object:  StoredProcedure [dbo].[USP_UPD_RPTN_DETAIL]    Script Date: 4/25/2017 3:35:43 PM ******/ 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[USP_UPD_RPTN_DETAIL] 
	 @pintClaimId AS INT = NULL
	,@pintPartyRoleID INT, @pintProgramAreaId AS INT
	,@tvpPetitionDisposition dbo.UDT_FOUR_COL_INT READONLY
	,@pintUEGFRptnDetsId AS INT=NULL
	,@pbitWCABAppealFlag BIT
	,@pdtDateOfInjury AS DATE, @pdtDateOfDeath AS DATE = NULL
	,@pintMedicalIndemnityId AS INT = NULL
	,@pstrInjuryDesc AS NVARCHAR(1000) = NULL
	,@pcurAvgWeeklyWage AS MONEY = NULL, @pcurCompRate AS MONEY = NULL
	,@pbitSpecificLossFlag AS BIT = NULL, @pintSpecificLossWeeks AS INT = NULL
	,@pbitHealingPeriodFlag AS BIT = NULL, @pintHealingPeriodWeeks AS INT = NULL
	,@pcurLitigationCost AS MONEY = NULL, @pbitInterstFlag AS BIT = NULL
	,@tvpIndemnityPayment dbo.UDT_THREE_INT_TWO_DT READONLY
	,@pdtNtceFileDate AS DATE = NULL, @pbitNtceFile45DaysFlag AS BIT = NULL
	,@pdtUEGFPaymentStartDate AS DATE = NULL, @pintEmployeeStatusTypeId AS INT = NULL
	,@pbitAvgWeeklyWageDeterminationFlag AS BIT = NULL
	,@tvpTaxPaidEvidence dbo.UDT_THREE_COL_INT READONLY
	,@tvpWageDetermination dbo.UDT_THREE_COL_INT READONLY
	,@pstrOtherWageDetermination AS NVARCHAR(100) = NULL
	,@pbitTaxPaidEvidenceFlag AS BIT = NULL
	,@pbitERFlag AS BIT = NULL ,@pbitEEFlag AS BIT = NULL
	,@tvpDeterminativeIssues dbo.UDT_THREE_COL_INT READONLY
	,@pintStipulationOrCandR INT
	,@pbitUEGFStipulationFlag AS BIT = NULL
	,@pintCRRptnTypeId AS INT = NULL
	,@tvpUegfReportingDetailCRSubDecision dbo.UDT_THREE_COL_INT READONLY
	,@pintCompromiseRptnTypeId AS INT = NULL
	,@pintCompromiseMedicalTypeId AS INT = NULL
	,@pcurTotalCRAmount AS MONEY = NULL
	,@pcurTotalFutureMedicalAmount AS MONEY = NULL
	,@pcurMedicareAsideAmount AS MONEY = NULL
	,@pintClaimantRepresentedFlagId AS INT = NULL
	,@tvpInterestedParties dbo.UDT_FOUR_COL_INT READONLY
	,@pintCrtdUpdtdBy AS INT
	,@pintCrtdUpdtdByOffice AS INT
	,@pintDraftOrComplete INT
	,@pintHistId INT=NULL, @pintFrmRptngHistId INT = NULL
AS
/*********************************************************************
 * Name:     [USP_UPD_RPTN_DETAIL]
 * Author:   c-mahsan
 * Date:     10 APR 2017
 *
 * Purpose/Description:
 *     Update a REPORTING detial record.
 *
 * Parameters:
 *	@tvpPetitionDisposition						PETITION POSITON TABLE
 *	@pintUEGFRptnDetsId							UEGF REPORTING DETAIL ID
 *	@pdtDateOfInjury							INJURY DATE
 *	@pdtDateOfDeath								DATE OF DEATH
 *	@pintMedicalIndemnityId						MEDICAL INDEMNITY PAYMENT IDENTIFIER
 *	@pstrInjuryDesc								INJURY DESCRIPTION FROM CLAIM INFORMATION
 *	@pcurAvgWeeklyWage							AVERAGE WEEKLY WAGE
 *	@pcurCompRate								COMPESATION RATE
 *	@pbitSpecificLossFlag						FLAG FOR SPECIFIC LOSS 
 *	@pintSpecificLossWeeks						NUMBER OF SPECIFIC LOSS WEEKS
 *	@pbitHealingPeriodFlag						HEALING PERIOD FLAG
 *	@pintHealingPeriodWeeks						NUMBER OF HEALING PERIOD WEEKS
 *	@pcurLitigationCost							LITIGATION COST
 *	@pbitInterstFlag							INTEREST FLAG
 *	@tvpIndemnityPayment						INDEMNITY PAYMENT TABLE
 *	@pdtNtceFileDate							NOTICE FILE DATE
 *	@pbitNtceFile45DaysFlag						Flag to check the notice filed within 45 DAYS
 *	@pdtUEGFPaymentStartDate					UEGF Payment Start Date
 *	@pintEmployeeStatusTypeId					Employee Status Id
 *	@pbitAvgWeeklyWageDeterminationFlag			Average Weekly Wage Determination Flag
 *	@tvpWageDetermination						WAGE DETERMINATION TABLE
 *	@pstrOtherWageDetermination					OTHER WAGE DETERMINAITON DESCRIPTION
 *	@pbitTaxPaidEvidenceFlag					ACCEPTED EVIDENCE OR TESTIMONY THAT PA TAXES WERE NOT PAID
 *	@pbitERFlag									ER FLAG
 *	@pbitEEFlag									EE FLAG
 *	@tvpDeterminativeIssues						DETERMINATIVE ISSUES
 *	@pbitStipulationFlag						STIMULATION FLAG
 *	@pbitCRFlag									COMPROMISE AND RELEASE FLAG
 *	@pbitUEGFStipulationFlag					UEGF STIPULATION FLAG
 *	@pintCRRptnTypeId							COMPROMISE AND RELEASE REPORTING
 *	@pbitCROtherERFlag							OTHER ER FLAG
 *	@pbitCROtherStatutoryFlag					OTHER STATUTORY FLAG
 *	@pbitCROtherInsurerFlag						OTHER INSURER FLAG
 *	@pbitCROtherUnknownFlag						OTHER UNKNOWN FLAG
 *	@pintCompromiseRptnTypeId					COMPROMISE REPORTING TYPE IDENTIFIER
 *	@pintCompromiseMedicalTypeId				COMPROMISE MEDICAL IDENTIFIER
 *	@pcurTotalCRAmount							TOTAL COMPROMISE AND RELEASE AMOUNT
 *	@pcurTotalFutureMedicalAmount				TOTAL AMOUNT DESIGNATED FOR FUTURE MEDICAL 
 *	@pcurMedicareAsideAmount					TOTAL MEDICARE ASIDE AMOUNT
 *	@pintClaimantRepresentedFlagId				IS THE CLAIMANT/ EMPLOYEE REPRESENTED FLAG
 *	@tvpInterestedParties						INTERESTED PARTIES/ ADDITIONAL DEFENDANTS REPONSIBILITES TABLE
 *	@pintCrtdUpdtdByOffice						CREATEDTD BY OFFICE USER ID
 *	@pintCrtdUpdtdBy							CREATED OR UPDATED BY USER ID
 *	@pstrOrigination							ORIGINATION NAME
 *	
 * Return:
 *     0 on success, otherwise error number
 *
 * Table and Alias Definitions:
 *     NONE 
 *  
 * Called Programs:
 *     NONE
 *
 *********************************************************************/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	DECLARE  @intOriginationId INT, @intPartyRoleTypeId AS INT,@xml XML
			,@intStaffId INT
			,@dtCurrentDate DATETIME = GETDATE()
			,@tvpPetitionDispositionRowCount INT = (SELECT ISNULL(count(COL1_ID), 0) FROM @tvpPetitionDisposition)
			,@tvpIndemnityPaymentRowCount INT = (SELECT ISNULL(count(COL1_ID), 0) FROM @tvpIndemnityPayment)
			,@tvpWageDeterminationRowCount INT =	(SELECT ISNULL(count(COL1_ID), 0) FROM @tvpWageDetermination)
			,@tvpDeterminativeIssuesRowCount INT = (SELECT ISNULL(count(COL1_ID), 0) FROM @tvpDeterminativeIssues)
			,@tvpInterestedPartiesRowCount AS INT = (SELECT ISNULL(count(COL1_ID), 0) FROM @tvpInterestedParties)
			,@tvpTaxPaidEvidenceRowCount AS INT = (SELECT ISNULL(COUNT(COL1_ID), 0) FROM @tvpTaxPaidEvidence)
			,@bitUpdatePermission AS BIT = 1, @intRptngStatusId INT = 2
	

		IF @pintClaimantRepresentedFlagId = 0
			SET @pintClaimantRepresentedFlagId = NULL 

	SELECT @intPartyRoleTypeId = PARTY_ROLE_TYPE_ID 
			FROM APP.T_PARTY_ROLE 
			WHERE APP.T_PARTY_ROLE.PARTY_ROLE_ID = @pintPartyRoleID 

	

	IF @tvpPetitionDispositionRowCount > 0
		BEGIN
			

		DECLARE @PetitionDispositionTempTable TABLE(DisputePetitionId INT, DsptPetitnTypeId INT, PetitionType nvarchar(500), DispositionTypeId int, OponDispnTypeId int)
		INSERT INTO @PetitionDispositionTempTable
		(
		    DisputePetitionId, DsptPetitnTypeId, PetitionType, DispositionTypeId, OponDispnTypeId
		)
		SELECT	tdp.DSPT_PETITN_ID AS 'DisputePetitionId' ,tdpt.DSPT_PETITN_TYPE_ID AS 'DsptPetitnTypeId' 
			,tdpt.DSPT_PETITN_TYPE_DESC +'('+CONVERT(varchar(10), tdp.PETITN_FILED_DT, 101)+')' AS 'PetitionType', 
			TPDT.COL3_ID AS 'DispositionTypeId', TPDT.COL4_ID AS 'OponDispnTypeId'
		FROM APP.T_DSPT_PETITN tdp	INNER JOIN	LKP.T_DSPT_PETITN_TYPE tdpt ON tdpt.DSPT_PETITN_TYPE_ID = tdp.DSPT_PETITN_TYPE_ID
		INNER JOIN @tvpPetitionDisposition TPDT ON TPDT.COL1_id = TDP.DSPT_PETITN_ID 
		WHERE tdp.DSPT_ID IS NOT NULL

		DECLARE @DsptPetnXml XML = (
			SELECT	DisputePetitionId, DsptPetitnTypeId, PetitionType, DispositionTypeId, OponDispnTypeId FROM @PetitionDispositionTempTable tdp
		FOR XML AUTO)

		END

	
		
		DECLARE @RptnDetailXml AS XML = (SELECT * FROM (
		SELECT
			NULL AS DisputeId, @pintClaimId AS ClaimId, @pdtDateOfInjury AS DateOfInjury, @pdtDateOfDeath AS DateOfDeath, 
			@pintMedicalIndemnityId AS 'MedicalIndemnityId',@pstrInjuryDesc AS 'InjuryDesc', @pcurAvgWeeklyWage AS 'AvgWeeklyWage',
			@pcurCompRate AS 'CompRate', @pbitSpecificLossFlag AS	'SpecificLossFlag', @pintSpecificLossWeeks AS 'SpecificLossWeeks',
			@pbitHealingPeriodFlag AS 'HealingPeriodFlag', @pintHealingPeriodWeeks AS 'HealingPeriodWeeks', @pcurLitigationCost AS 'LitigationCost',
			@pbitInterstFlag AS 'InterstFlag', @pdtNtceFileDate AS	'NtceFileDate', @pbitNtceFile45DaysFlag AS 'NtceFile45DaysFlag',
			@pdtUEGFPaymentStartDate AS 'UEGFPaymentStartDate', @pintEmployeeStatusTypeId AS 'EmployeeStatusTypeId', 
			@pbitAvgWeeklyWageDeterminationFlag AS 'AvgWeeklyWageDeterminationFlag', @pstrOtherWageDetermination AS 'OtherWageDetermination',
			--tudd.TAX_PAID_EVID_FLAG AS 'TaxPaidEvidenceFlag', tudd.EE_FLAG AS 'EEFlag', tudd.ER_FLAG AS 'ERFlag',
			@pintStipulationOrCandR AS	'StipulationOrCandR', @pbitUEGFStipulationFlag AS 'UEGFStipulationFlag',
			@pintCRRptnTypeId AS 'CRRptnTypeId',@pintCompromiseRptnTypeId AS 'CompromiseRptnTypeId',
			@pintCompromiseMedicalTypeId AS 'CompromiseMedicalTypeId', @pcurTotalCRAmount  AS 'TotalCRAmount', @pcurTotalFutureMedicalAmount AS 'TotalFutureMedicalAmount',
			@pcurMedicareAsideAmount AS 'MedicareAsideAmount', @pintClaimantRepresentedFlagId AS 'ClaimantRepresentedFlagId', 0 AS 'FrmRptngHistId'
		) AS turd
		FOR XML AUTO)

			
		DECLARE @IndmPaytXml XML = (
			SELECT 0 AS 'UEGFIndemnityPaymentId', 0 AS 'UEGFRptnDetsId',
				tuip.COL3_ID AS 'DisablityTypeId',
			CASE	WHEN tuip.COL3_ID = 1 THEN 'TTD'
					WHEN tuip.COL3_ID = 2 THEN 'TPD'
			END AS 'DisablityTypeDesc', tuip.COL4_DATE AS 'PaymentStartDate', tuip.COL5_DATE AS 'PaymentEndDate'
			FROM @tvpIndemnityPayment tuip
		FOR XML AUTO)
		


		DECLARE @RptnWageDeterXml XML = (
			SELECT 0 AS 'UEGFRptnDetsId', 0 AS 'UEGFRptnWageDeterId', 
				tudwd.COL3_ID AS 'WageDeterminationTypeId', twdt.WAGE_DETER_TYPE_DESC AS 'WageDeterminationTypeDesc'
			FROM @tvpWageDetermination tudwd INNER JOIN LKP.T_WAGE_DETER_TYPE twdt ON twdt.WAGE_DETER_TYPE_ID = tudwd.COL3_ID
		FOR XML AUTO)
			


		DECLARE @RptnDeterIssueXml XML = (
			SELECT 0 AS 'UEGFRptnDetsId', tuddi.COL3_ID AS 'DeterminaitionIssueTypeId', 
				tdit.DETER_ISSUE_TYPE_DESC AS 'DeterminaitonIssueTypeDesc'
			FROM @tvpDeterminativeIssues tuddi INNER JOIN LKP.T_DETER_ISSUE_TYPE tdit ON tdit.DETER_ISSUE_TYPE_ID = tuddi.COL3_ID
		FOR XML AUTO)
		
			
		DECLARE @TaxPaidEvidXml AS XML = (
			SELECT 0 AS 'RptngTaxPaidEvidId', 0 AS 'RptngDetailId', turtpe.COL3_ID AS 'TaxPaidEvidId' 
			FROM @tvpTaxPaidEvidence turtpe
		FOR XML AUTO)
		


		DECLARE @ReportingDetailCRSubDecisionXml AS XML = (
			SELECT 0 AS 'UEGFReportingDetailCRSubDecisionId', 0 AS 'UEGFreportingDetailId', turdcsd.COL3_ID AS 'CompromiseAndReleaseDecisionSubTypeId'
			FROM @tvpUegfReportingDetailCRSubDecision turdcsd
		FOR XML AUTO)
			


			--SELECT turipr.MatterPartyId AS 'MatterPartyId',
			--	turipr.PartyRoleTypeId AS 'PartyRoleTypeId',
			--	turipr.CorrespondenceMatterPartyName AS 'Name',
			--	turipr.MatterPartyRole AS 'Type',
			--	0 AS 'RspbSeqnTypeId',
			--	turipr.MatterPartyDesc AS 'PartyType'

		DECLARE @IntdPartXml XML = (
			SELECT turipr.COL4_ID AS 'RspbSeqnTypeId',
				turipr.COL3_ID AS 'MatterPartyId'
			FROM @tvpInterestedParties turipr
		FOR XML AUTO)

		SET @xml = (
			SELECT (SELECT @RptnDetailXml)
				,(SELECT @RptnDeterIssueXml)
				,(SELECT @RptnWageDeterXml)
				,(SELECT @DsptPetnXml)
				,(SELECT @IndmPaytXml)
				,(SELECT @IntdPartXml)
				,(SELECT @TaxPaidEvidXml)
				,(SELECT @ReportingDetailCRSubDecisionXml)
				FOR XML PATH(''))

		


		--			DSPT_PETITN_STATUS_ID	DSPT_PETITN_STATUS_DESC
		--						2			Closed                   
		
	
	IF @pintDraftOrComplete = 2
		SET	@intOriginationId = 3 --Correction SELECT * FROM LKP.T_UEGF_RPTNG_ORIGINATION
	ELSE
		SET	@intOriginationId = NULL 
			
	IF EXISTS ( SELECT * FROM APP.T_UEGF_RPTNG_HIST WHERE CLAIM_ID = @pintClaimId AND  PROG_AREA_ID = @pintProgramAreaId AND RPTNG_HIST_STATUS_ID = 1) 		
			SELECT @pintHistId= UEGF_RPTNG_HIST_ID, @intRptngStatusId = RPTNG_HIST_STATUS_ID FROM APP.T_UEGF_RPTNG_HIST WHERE CLAIM_ID = @pintClaimId AND  PROG_AREA_ID = @pintProgramAreaId AND RPTNG_HIST_STATUS_ID = 1



	--CREATING SNAPSHOT
	IF ((@pintHistId IS NOT NULL) AND (@intRptngStatusId = 1))
		UPDATE TURH SET HIST_XML= @xml, RPTNG_HIST_STATUS_ID = @pintDraftOrComplete, PROG_AREA_ID = @pintProgramAreaId,
								UPDTD_BY = @pintCrtdUpdtdBy, UPDATE_DATE = @dtCurrentDate, UPDATE_TIME = @dtCurrentDate, UPDTD_BY_OFFICE= @pintCrtdUpdtdByOffice, 
								STAFF_ID = @pintCrtdUpdtdBy, UEGF_RPTNG_ORIGINATION_ID = @intOriginationId
		FROM APP.T_UEGF_RPTNG_HIST TURH
		WHERE (TURH.UEGF_RPTNG_HIST_ID = @pintHistId)
	ELSE
		INSERT INTO APP.T_UEGF_RPTNG_HIST
				(HIST_XML, FROM_RPTNG_HIST_ID , RPTNG_HIST_STATUS_ID , PROG_AREA_ID, CLAIM_ID, CRTD_BY,CREATE_DATE,CREATE_TIME,CRTD_BY_OFFICE, UPDTD_BY , UPDATE_DATE , UPDATE_TIME , UPDTD_BY_OFFICE, STAFF_ID, UEGF_RPTNG_ORIGINATION_ID)
		VALUES	(@xml, @pintFrmRptngHistId, @pintDraftOrComplete, @pintProgramAreaId, @pintClaimId, @pintCrtdUpdtdBy, @dtCurrentDate, @dtCurrentDate, @pintCrtdUpdtdByOffice, @pintCrtdUpdtdBy, @dtCurrentDate, @dtCurrentDate, @pintCrtdUpdtdByOffice, @pintCrtdUpdtdBy, @intOriginationId)

	--UPDATING THE CLAIM STATUS AND PAYMENT STATUS FOR OUTSTANDING PAYMENT SCREEN
	IF @pintDraftOrComplete = 2
		--EXECUTE dbo.USP_UPD_UEGF_CLAIM_STATUS_EX @pintClaimId, @pintCrtdUpdtdBy, @pintCrtdUpdtdByOffice
			EXECUTE  dbo.USP_INS_RPTN_DETAIL_HIST @pintClaimId, @pintCrtdUpdtdBy, @pintCrtdUpdtdByOffice
END