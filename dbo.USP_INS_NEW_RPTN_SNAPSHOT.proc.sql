
/****** Object:  StoredProcedure [dbo].[USP_INS_NEW_RPTN_SNAPSHOT]    Script Date: 8/9/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

ALTER PROCEDURE [dbo].[USP_INS_NEW_RPTN_SNAPSHOT]
	 @pintClaimId INT	
	,@pintProgramAreaID INT
	,@pintCrtdUpdtdBy INT
	,@pintCrtdUpdtdByOffice INT
	,@intDraftHistoryId INT OUTPUT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].[USP_INS_NEW_RPTN_SNAPSHOT]
 * Author:   c-mahsan
 * Date:     8/9/2017
 *
 * Purpose/Description: 
 *     Retrieve UEGF Claim Details
 *
 * Parameters:
 *     @pintClaimId				Claim IDENTIFIER 
 *     @pintProgramAreaID		Program Area IDENTIFIER 
 *     @intDraftHistoryId		History Number
 *
 * Return:
 *     NONE
 *
 * Table and Alias Definitions:
 *		APP.T_INJURY_DETAIL
 *		APP.T_INDIV
 *  
 * Called Programs:
 *     NONE
 * 
 *********************************************************************/	
 
 SET NOCOUNT ON;  
	DECLARE @RptnWageDeterTempTable TABLE(UEGFRptnDetsId int, UEGFRptnWageDeterId int, WageDeterminationTypeId int)
	DECLARE @DeterIssueTempTable TABLE(UEGFRptnDetsId int, DeterminaitionIssueTypeId int)
	DECLARE @IntdPatiesOrAddnDfdtRspbTempTable TABLE(PartyRoleTypeId int, RspbSeqnTypeId int, MatterPartyId int, MatterPartyRole VARCHAR(100), CorrespondenceMatterPartyName VARCHAR(200), PartyType VARCHAR(100))
	DECLARE @IndemnityPayTempTable TABLE(UEGFIndemnityPaymentId INT, UEGFRptnDetsId INT, DisablityTypeId INT, DisablityTypeDesc NVARCHAR(100), PaymentStartDate DATE, PaymentEndDate DATE)
	DECLARE @TaxPaidEvidTempTable TABLE(UEGFReportingTaxPaidEvidenceId INT, UEGFReportingDetailsId INT, TaxPaidEvidenceId INT)
	DECLARE @ReportingDetailCRSubDecisionTempTable TABLE(UEGFReportingDetailCRSubDecisionId INT, UEGFreportingDetailId INT, CompromiseAndReleaseDecisionSubTypeId INT)
	DECLARE  @dtCurrent DATETIME = GETDATE(), @dateDateOfInjury DATE, @dateDatOfDeath DATE, @intMedicalIndemnityPaymentTypeId INT = 3 --BIZ-BWC-UEGF-Award Details Panel - Med, Indemnity, or Both - Defaulted to Both = 3
			,@dateNoticeFileDate DATE, @moneyAvgWeeklyWage MONEY, @moneyCompRate MONEY, @intCnRDecisionId INT, @intCnRMedicalId INT, @moneyTotalCnRAmount MONEY, @moneyFutureMedical MONEY, @moneyMedicareSetAsideAmount MONEY
			,@intIsClaimantEmployeeRepresentedId INT, @strInjurydescription NVARCHAR(1000), @xml XML, @intWCABAppealFlag INT

DECLARE  @intFromHistId INT = NULL 
		
	

 	IF NOT EXISTS ( SELECT * FROM APP.T_UEGF_RPTNG_HIST URH
						WHERE URH.RPTNG_HIST_STATUS_ID = 2 AND URH.CLAIM_ID = @pintClaimId)
	BEGIN
	--INSERT DEFAULT VALUES IN THE XML 

	--Reading DOI
	IF @dateDateOfInjury IS NULL
		
		SELECT @dateDateOfInjury = tc.INJURY_DT
		FROM APP.T_CLAIM tc
		WHERE (tc.CLAIM_ID = @pintClaimId)

	SELECT TOP 1 @dateDatOfDeath = ti.DOD
	FROM APP.T_INDIV TI 
	INNER JOIN APP.T_PARTY_ROLE TPR ON TPR.PARTY_ID = TI.PARTY_ID
	INNER JOIN APP.T_MATTER_PARTY TMP ON TPR.PARTY_ROLE_ID = TMP.PARTY_ROLE_ID
	WHERE TMP.CLAIM_ID = @pintClaimId

	SELECT TOP 1 @moneyAvgWeeklywage = ISNULL(@moneyAvgWeeklywage,  AVG_WEEKLY_WAGE), @moneyCompRate = ISNULL(@moneyCompRate, CALCD_WEEKLY_COMPENSABLE_AMOUNT)
	FROM APP.T_CLAIM_DETAIL TCD 
	INNER JOIN APP.T_CLAIM_HIST TCHI ON TCD.CLAIM_HIST_ID = TCHI.CLAIM_HIST_ID
	WHERE TCHI.CLAIM_ID = @pintClaimId
	ORDER BY TCD.UPDATE_DATE DESC, TCD.UPDATE_TIME DESC
	
	--Getting Injury Description
	SELECT @strInjurydescription = tid.INJURY_DESC
	FROM APP.T_INJURY_DETAIL tid INNER JOIN APP.T_CLAIM_HIST tch ON tch.CLAIM_HIST_ID = tid.CLAIM_HIST_ID
	WHERE tch.CLAIM_ID = @pintClaimId
	
	--RETRIEVING OLDEST NOTICE FILE DATE		
	SELECT TOP	1 @dateNoticeFileDate = ISNULL(TUN.DT_PRCSD, UPDATE_DATE)
	FROM APP.T_UEGF_NOTICE TUN
	WHERE TUN.CLAIM_ID = @pintClaimId AND TUN.UEGF_STATUS_TYPE_ID = 1 -- 1= Accepted
	ORDER BY TUN.DT_PRCSD

	--SELECT TOP 1 @moneyTotalCnRAmount = td.TOTAL_C_AND_R_AMOUNT, @moneyFutureMedical = td.TOTAL_FURTHER_MED_AMOUNT, @moneyMedicareSetAsideAmount = td.TOTAL_MDCARE_AMOUNT, @intCnRDecisionId = td.COMPRMS_DECN_TYPE_ID, 
	--@intCnRMedicalId = td.COMPRMS_MED_TYPE_ID, @intIsClaimantEmployeeRepresentedId = td.CLMT_REPRTED_FLAG
	--FROM APP.T_DSPT td
	--WHERE td.CLAIM_ID = @pintClaimId
	--ORDER BY td.UPDATE_DATE DESC, td.UPDATE_TIME DESC

	--IF APPEAL IS ACCEPTED CHECK
	SELECT @intWCABAppealFlag = 1
	FROM APP.T_APPEAL_CASE AC
	INNER JOIN APP.T_APPEAL_PETITN AP ON AC.APPEAL_CASE_ID = AP.APPEAL_CASE_ID
	WHERE AP.APPEAL_PETITN_STATUS_TYPE_ID = 2 AND AC.CLAIM_ID = @pintClaimId
	
	--Petition Table
	DECLARE @PetitionDispositionTempTable TABLE(DsptId INT, DisputePetitionId INT, DsptPetitnTypeId INT, PetitionType nvarchar(500), DispositionTypeId int, OponDispnTypeId int, OpinionDispositionEnable INT)
		INSERT INTO @PetitionDispositionTempTable
		(
		    DsptId, DisputePetitionId, DsptPetitnTypeId, PetitionType, DispositionTypeId, OponDispnTypeId,OpinionDispositionEnable
		)
		SELECT tdp.DSPT_ID AS DsptId,	tdp.DSPT_PETITN_ID AS 'DisputePetitionId' ,tdpt.DSPT_PETITN_TYPE_ID AS 'DsptPetitnTypeId' 
			,tdpt.DSPT_PETITN_TYPE_DESC +'('+CONVERT(varchar(10), tdp.PETITN_FILED_DT, 101)+')' AS 'PetitionType', 
			null AS 'DispositionTypeId', null AS 'OponDispnTypeId'
			,CASE WHEN AC.APPEAL_CASE_ID IS NULL THEN 0 ELSE 1 END AS 'OpinionDispositionEnable'
		FROM APP.T_DSPT_PETITN tdp	
		INNER JOIN	LKP.T_DSPT_PETITN_TYPE tdpt ON tdpt.DSPT_PETITN_TYPE_ID = tdp.DSPT_PETITN_TYPE_ID
		LEFT JOIN (SELECT DISTINCT AC.DSPT_ID, AC.APPEAL_CASE_ID 
														FROM APP.T_APPEAL_CASE AC
														INNER JOIN APP.T_APPEAL_PETITN AP ON AP.APPEAL_CASE_ID = AC.APPEAL_CASE_ID
														WHERE ac.CLAIM_ID = @pintClaimId AND APPEAL_PETITN_STATUS_TYPE_ID IN (2,5))
					AC ON AC.DSPT_ID = TDP.DSPT_ID 
		WHERE	tdp.CLAIM_ID	= @pintClaimId AND tdp.DSPT_ID IS NOT NULL

		--DECLARE @DsptPetnXml XML = (
			SELECT	DsptId, DisputePetitionId, DsptPetitnTypeId, PetitionType, DispositionTypeId, OponDispnTypeId, OpinionDispositionEnable FROM @PetitionDispositionTempTable tdp
		--FOR XML AUTO)

	--Indemnity Payment Table
	SELECT iptt.UEGFRptnDetsId, iptt.DisablityTypeId, iptt.DisablityTypeDesc, iptt.PaymentStartDate, iptt.PaymentEndDate FROM @IndemnityPayTempTable iptt
	

	--WAGE DETERMINATION TABLE
	SELECT rwdtt.UEGFRptnDetsId, rwdtt.UEGFRptnWageDeterId, rwdtt.WageDeterminationTypeId, twdt.WAGE_DETER_TYPE_DESC
	FROM @RptnWageDeterTempTable rwdtt INNER JOIN LKP.T_WAGE_DETER_TYPE twdt ON twdt.WAGE_DETER_TYPE_ID = rwdtt.WageDeterminationTypeId

	--TAX EVIDENCE TABLE
	SELECT UEGFReportingTaxPaidEvidenceId, UEGFReportingDetailsId, TaxPaidEvidenceId
	FROM @TaxPaidEvidTempTable tpett

	--DETERMINATION ISSUE TABLE
	SELECT ditt.UEGFRptnDetsId, ditt.DeterminaitionIssueTypeId, tdit.DETER_ISSUE_TYPE_DESC
		FROM @DeterIssueTempTable ditt INNER JOIN LKP.T_DETER_ISSUE_TYPE tdit ON ditt.DeterminaitionIssueTypeId = tdit.DETER_ISSUE_TYPE_ID

	--Interested Parties Table
	DECLARE @IntdPatiesOrAddnDfdtRspb TABLE (CorrespondenceMatterPartyName VARCHAR(200), MatterPartyRole VARCHAR(100), PartyRoleTypeId INT, MatterPartyDesc VARCHAR(100), MatterPartyId INT)
		INSERT INTO @IntdPatiesOrAddnDfdtRspb(CorrespondenceMatterPartyName , MatterPartyRole , PartyRoleTypeId , MatterPartyDesc, MatterPartyId)
			(SELECT CorrespondenceMatterPartyName, MatterPartyRole, PartyRoleTypeId, MatterPartyDesc, MatterPartyId
			FROM dbo.udf_get_parties_for_matter(@pintClaimId,2,2, default)
			WHERE PartyRoleTypeId IN (13,24,37,202)
			UNION 
			SELECT CorrespondenceMatterPartyName, MatterPartyRole, PartyRoleTypeId, MatterPartyDesc, MatterPartyId
			FROM dbo.udf_get_parties_for_matter(@pintClaimId,2,5, default) 
			WHERE PartyRoleTypeId IN (13,24,37,202))
		--DECLARE @IntdPartXml XML = (
			SELECT turipr.MatterPartyId AS 'MatterPartyId',
				turipr.PartyRoleTypeId AS 'PartyRoleTypeId',
				turipr.CorrespondenceMatterPartyName AS 'Name',
				turipr.MatterPartyRole AS 'Type',
				0 AS 'RspbSeqnTypeId',
				turipr.MatterPartyDesc AS 'PartyType'
			FROM @IntdPatiesOrAddnDfdtRspb turipr
		--FOR XML AUTO)


		--Reporting Details Data
		--DECLARE @RptnDetailXml AS XML = (		 
			SELECT * FROM
			(SELECT 
			NULL AS 'DisputeId', @pintClaimId AS 'ClaimId', NULL AS 'HideReportingDetails', NULL AS 'EditPermission', @intWCABAppealFlag AS 'WCABAppealFlag'
			,NULL	AS 'UEGFRptnDetsId', @dateDateOfInjury AS 'DateOfInjury', @dateDatOfDeath AS 'DateOfDeath', @intMedicalIndemnityPaymentTypeId AS 'MedicalIndemnityId',
			@strInjurydescription AS 'InjuryDesc', @moneyAvgWeeklyWage AS 'AvgWeeklyWage', @moneyCompRate AS 'CompRate', NULL AS	'SpecificLossFlag',
			NULL AS 'SpecificLossWeeks', NULL AS 'HealingPeriodFlag', NULL AS 'HealingPeriodWeeks', NULL AS 'LitigationCost',
			NULL AS 'InterstFlag', @dateNoticeFileDate AS	'NtceFileDate', NULL AS 'NtceFile45DaysFlag', NULL AS 'UEGFPaymentStartDate',
			NULL AS 'EmployeeStatusTypeId', NULL AS 'AvgWeeklyWageDeterminationFlag', NULL AS 'OtherWageDetermination', NULL AS 'TaxPaidEvidenceFlag', NULL AS 'EEFlag', NULL AS 'ERFlag', 
			NULL AS 'StipulationOrCandR', NULL AS 'UEGFStipulationFlag', NULL AS 'CRRptnTypeId', @intCnRDecisionId AS 'CompromiseRptnTypeId', @intCnRMedicalId AS 'CompromiseMedicalTypeId'
			, @moneyTotalCnRAmount AS 'TotalCRAmount', @moneyFutureMedical AS 'TotalFutureMedicalAmount' ,@moneyMedicareSetAsideAmount AS 'MedicareAsideAmount', @intIsClaimantEmployeeRepresentedId AS 'ClaimantRepresentedFlagId') AS turd
		--FOR XML AUTO)
	

	--CR SUB DECISION TABLE
	SELECT NULL AS UEGFReportingDetailCRSubDecisionId, NULL AS UEGFreportingDetailId, NULL AS CompromiseAndReleaseDecisionSubTypeId WHERE 1 <> 1
		

		SELECT NULL AS 'UpdatedBy',
					NULL AS 'UpdatedDate' WHERE 1 <> 1 
			
END
	ELSE
	BEGIN
		--GET THE LATEST SNAPSHOT AND INSERT IT AS DRAFT FOR THE PROGRAM AREA
		
		SELECT TOP 1 @intFromHistId =UEGF_RPTNG_HIST_ID  FROM APP.T_UEGF_RPTNG_HIST
		WHERE CLAIM_ID  = @pintClaimId AND RPTNG_HIST_STATUS_ID = 2 
		ORDER BY UPDATE_DATE DESC, UPDATE_TIME DESC 

		SET @intDraftHistoryId = @intFromHistId
		--Get the details
		EXEC [dbo].[USP_SEL_RPTN_DETAIL_HIST] @intFromHistId, 1

		
	END
		
END