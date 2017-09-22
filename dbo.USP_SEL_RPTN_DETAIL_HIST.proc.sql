/****** Object:  StoredProcedure [dbo].[USP_SEL_RPTN_DETAIL_HIST]    Script Date: 4/20/2017 6:57:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[USP_SEL_RPTN_DETAIL_HIST]
	 @pintHistId AS int
	,@intDraftStatus INT = 2
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].[USP_SEL_RPTN_DETAIL_HIST]
 * Author:   c-mahsan
 * Date:     06 APR 2017
 *
 * Purpose/Description:
 *     Retrieve record relating to the dispute number
 *
 * Parameters:
 *     @pintHistId	Unique History Identifier
 *
 * Return:
 *     APP.T_UEGF_RPTNG_DETAIL, APP.T_DSPT_PETITN, APP.T_UEGF_INDEMNITY_PMT, APP.T_UEGF_RPTNG_WAGE_DETER, APP.T_UEGF_RPTNG_DETER_ISSUE, APP.T_UEGF_RPTNG_INTD_PARTY_RESPBLT
 *
 * Table and Alias Definitions:
 *     T_UEGF_RPTNG_HIST , tudh
 *  
 * Called Programs:
 *     NONE
 *
 *********************************************************************/	
 
 SET NOCOUNT ON;
	
	DECLARE	@intDsptId AS int, @intClaimId INT, @intFrmHistId INT, @intWCABAppealFlag INT, @intrecordDraftStatus INT, @strUpdatedBy NVARCHAR(100), @dtUpdatedDate DATE,
			@intCnRDecisionId INT, @moneyAvgWeeklyWage MONEY = NULL, @moneyCompRate MONEY = NULL, @moneyTotalCnRAmount MONEY = NULL, @moneyFutureMedical MONEY = NULL, @moneyMedicareSetAsideAmount MONEY = NULL, @intCnRMedicalId INT
			, @intIsClaimantEmployeeRepresentedId INT, @dateNoticeFileDate DATE, @xmlHist AS XML, @dateDateOfInjury DATE
	DECLARE @RptnWageDeterTempTable TABLE(UEGFRptnDetsId int, UEGFRptnWageDeterId int, WageDeterminationTypeId int)
	DECLARE @DeterIssueTempTable TABLE(UEGFRptnDetsId int, DeterminaitionIssueTypeId int)
	DECLARE @IntdPatiesOrAddnDfdtRspbTempTable TABLE(PartyRoleTypeId int, RspbSeqnTypeId int, MatterPartyId int, MatterPartyRole VARCHAR(100), CorrespondenceMatterPartyName VARCHAR(200), PartyType VARCHAR(100))
	DECLARE @IndemnityPayTempTable TABLE(UEGFIndemnityPaymentId INT, UEGFRptnDetsId INT, DisablityTypeId INT, DisablityTypeDesc NVARCHAR(100), PaymentStartDate DATE, PaymentEndDate DATE)
	DECLARE @TaxPaidEvidTempTable TABLE(UEGFReportingTaxPaidEvidenceId INT, UEGFReportingDetailsId INT, TaxPaidEvidenceId INT)
	DECLARE @ReportingDetailCRSubDecisionTempTable TABLE(UEGFReportingDetailCRSubDecisionId INT, UEGFreportingDetailId INT, CompromiseAndReleaseDecisionSubTypeId INT)
	
		
	SELECT @xmlHist = trdh.HIST_XML, @intClaimId = trdh.CLAIM_ID, @intrecordDraftStatus =RPTNG_HIST_STATUS_ID, @strUpdatedBy = dbo.UDF_PARTY_NAME(trdh.UPDTD_BY), @dtUpdatedDate = trdh.UPDATE_DATE
	FROM APP.T_UEGF_RPTNG_HIST trdh WHERE trdh.UEGF_RPTNG_HIST_ID = @pintHistId
	
	----Reading value for parameter @pintDsptId
	--SELECT @intDsptId = Col.value('@DisputeId', 'int'),  @intClaimId = Col.value('@ClaimId', 'int'), @intUEGFRptnDetsId= Col.value('@UegfRptnDetsId', 'int')
	--	FROM @xmlHist.nodes('/turd') AS Data(Col)

	--SELECT TOP 1 @moneyTotalCnRAmount = td.TOTAL_C_AND_R_AMOUNT, @moneyFutureMedical = td.TOTAL_FURTHER_MED_AMOUNT, @moneyMedicareSetAsideAmount = td.TOTAL_MDCARE_AMOUNT, @intCnRDecisionId = td.COMPRMS_DECN_TYPE_ID, 
	--@intCnRMedicalId = td.COMPRMS_MED_TYPE_ID, @intIsClaimantEmployeeRepresentedId = td.CLMT_REPRTED_FLAG
	--FROM APP.T_DSPT td
	--WHERE td.CLAIM_ID = @intClaimId
	--ORDER BY td.UPDATE_DATE DESC, td.UPDATE_TIME DESC
	
	

	--IF APPEAL IS ACCEPTED CHECK
	SELECT @intWCABAppealFlag = 1
	FROM APP.T_APPEAL_CASE AC
	INNER JOIN APP.T_APPEAL_PETITN AP ON AC.APPEAL_CASE_ID = AP.APPEAL_CASE_ID
	WHERE AP.APPEAL_PETITN_STATUS_TYPE_ID = 2 AND AC.CLAIM_ID = @intClaimId

	--DECLARE @PetitionDispositionTempTable TABLE(DisputePetitionId INT, DsptPetitnTypeId INT, PetitionType )

	IF @intDraftStatus = 1 --Draft
	BEGIN
		IF @intrecordDraftStatus = 2
		BEGIN
			SET @intFrmHistId = @pintHistId
			SET @pintHistId = NULL
		END
		
	SELECT tdp.DSPT_ID AS 'DsptId',
		tdp.DSPT_PETITN_ID AS 'DisputePetitionId' ,
		tdpt.DSPT_PETITN_TYPE_ID AS 'DsptPetitnTypeId' 
			,tdpt.DSPT_PETITN_TYPE_DESC +'('+CONVERT(varchar(10), tdp.PETITN_FILED_DT, 101)+')' AS 'PetitionType', 
		Col.value('@DispositionTypeId', 'INT') AS 'DispositionTypeId',
		Col.value('@OponDispnTypeId', 'INT') AS 'OponDispnTypeId',
		CASE WHEN AC.DSPT_ID IS NULL THEN 0 ELSE 1 END AS 'OpinionDispositionEnable'
	FROM @xmlHist.nodes('/tdp') AS Data(Col)
	RIGHT JOIN APP.T_DSPT_PETITN tdp ON tdp.DSPT_PETITN_ID = Col.value('@DisputePetitionId', 'INT') 
	RIGHT JOIN	LKP.T_DSPT_PETITN_TYPE tdpt ON tdpt.DSPT_PETITN_TYPE_ID = tdp.DSPT_PETITN_TYPE_ID
	LEFT JOIN (SELECT DISTINCT AC.DSPT_ID
														FROM APP.T_APPEAL_CASE AC
														INNER JOIN APP.T_APPEAL_PETITN AP ON AP.APPEAL_CASE_ID = AC.APPEAL_CASE_ID
														WHERE ac.CLAIM_ID = @intClaimId AND APPEAL_PETITN_STATUS_TYPE_ID IN (2,5))
					AC ON AC.DSPT_ID = TDP.DSPT_ID 
	WHERE  tdp.CLAIM_ID = @intClaimId AND TDP.DSPT_ID IS NOT NULL

	END 
	ELSE
	IF @intDraftStatus = 2 --COMPLETED
	BEGIN 
		
		SELECT 
			Col.value('@DisputePetitionId', 'INT') AS 'DisputePetitionId'
			,Col.value('@DsptPetitnTypeId', 'INT') AS 'DsptPetitnTypeId'
			,Col.value('@PetitionType', 'VARCHAR(200)') AS 'PetitionType',
			Col.value('@DispositionTypeId', 'INT') AS 'DispositionTypeId',
			Col.value('@OponDispnTypeId', 'INT') AS 'OponDispnTypeId'
		FROM @xmlHist.nodes('/tdp') AS Data(Col)
	END 
	
	INSERT INTO @IndemnityPayTempTable
	(
	    UEGFIndemnityPaymentId, UEGFRptnDetsId, DisablityTypeId, DisablityTypeDesc, PaymentStartDate, PaymentEndDate
	)
	SELECT 
		Col.value('@UEGFIndemnityPaymentId', 'int') AS 'UEGFIndemnityPaymentId',
		Col.value('@UEGFRptnDetsId', 'int') AS 'UEGFRptnDetsId',
		Col.value('@DisablityTypeId', 'int') AS 'DisablityTypeId',
		Col.value('@DisablityTypeDesc', 'nvarchar(100)') AS 'DisablityTypeDesc',
		Col.value('@PaymentStartDate', 'date') AS 'PaymentStartDate',
		Col.value('@PaymentEndDate', 'date') AS 'PaymentEndDate'
	FROM @xmlHist.nodes('/tuip') AS Data(Col)

	SELECT iptt.UEGFRptnDetsId, iptt.DisablityTypeId, iptt.DisablityTypeDesc, iptt.PaymentStartDate, iptt.PaymentEndDate FROM @IndemnityPayTempTable iptt

	INSERT INTO @RptnWageDeterTempTable
	(
	    UEGFRptnDetsId, UEGFRptnWageDeterId, WageDeterminationTypeId
	)
	SELECT 
		Col.value('@UEGFRptnDetsId', 'int') AS 'UEGFRptnDetsId', Col.value('@UEGFRptnWageDeterId', 'int') AS 'UEGFRptnWageDeterId',
		Col.value('@WageDeterminationTypeId', 'int') AS 'WageDeterminationTypeId'
	FROM @xmlHist.nodes('/tudwd') AS Data(Col)
	
	SELECT rwdtt.UEGFRptnDetsId, rwdtt.UEGFRptnWageDeterId, rwdtt.WageDeterminationTypeId, twdt.WAGE_DETER_TYPE_DESC
	FROM @RptnWageDeterTempTable rwdtt INNER JOIN LKP.T_WAGE_DETER_TYPE twdt ON twdt.WAGE_DETER_TYPE_ID = rwdtt.WageDeterminationTypeId
	
	
	INSERT INTO @TaxPaidEvidTempTable
	(
	    UEGFReportingTaxPaidEvidenceId, UEGFReportingDetailsId, TaxPaidEvidenceId
	)
	SELECT Col.value('@RptngTaxPaidEvidId', 'INT') AS 'UEGFReportingTaxPaidEvidenceId', Col.value('@RptngDetailId', 'INT') AS 'UEGFReportingDetailsId',
		Col.value('@TaxPaidEvidId', 'INT') AS 'TaxPaidEvidenceId'
	FROM @xmlHist.nodes('/turtpe') AS Data(Col)
	SELECT UEGFReportingTaxPaidEvidenceId, UEGFReportingDetailsId, TaxPaidEvidenceId
	FROM @TaxPaidEvidTempTable tpett

		INSERT INTO @DeterIssueTempTable
		(
		    UEGFRptnDetsId, DeterminaitionIssueTypeId
		)
		SELECT
				Col.value('@UEGFRptnDetsId', 'int') AS 'UEGFRptnDetsId', Col.value('@DeterminaitionIssueTypeId', 'int') AS 'DeterminaitionIssueTypeId'
		FROM @xmlHist.nodes('/tuddi') AS Data(Col)

		SELECT ditt.UEGFRptnDetsId, ditt.DeterminaitionIssueTypeId, tdit.DETER_ISSUE_TYPE_DESC
		FROM @DeterIssueTempTable ditt INNER JOIN LKP.T_DETER_ISSUE_TYPE tdit ON ditt.DeterminaitionIssueTypeId = tdit.DETER_ISSUE_TYPE_ID
		

		INSERT INTO @IntdPatiesOrAddnDfdtRspbTempTable
		(
			RspbSeqnTypeId, MatterPartyId, PartyRoleTypeId, CorrespondenceMatterPartyName, MatterPartyRole, PartyType
		)
		SELECT Col.value('@RspbSeqnTypeId', 'int') AS RspbSeqnTypeId,
			Col.value('@MatterPartyId', 'int') AS MatterPartyId,
			Col.value('@PartyRoleTypeId', 'int') AS PartyRoleTypeId,
			Col.value('@Name', 'VARCHAR(200)') AS CorrespondenceMatterPartyName,
			Col.value('@Type', 'VARCHAR(100)') AS MatterPartyRole,
			Col.value('@PartyType', 'VARCHAR(100)') AS PartyType
		FROM @xmlHist.nodes('/turipr') AS Data(Col);
		
		DECLARE @IntdPatiesOrAddnDfdtRspb TABLE (CorrespondenceMatterPartyName VARCHAR(200), MatterPartyRole VARCHAR(100), PartyRoleTypeId INT, MatterPartyDesc VARCHAR(100), MatterPartyId INT)
		
			
			
	IF @intDraftStatus <> 1--COMPLETED

		SELECT ipoadtt.MatterPartyId AS 'MatterPartyId',
				mp.PartyRoleTypeId AS 'PartyRoleTypeId',
				mp.CorrespondenceMatterPartyName AS 'Name',
				mp.MatterPartyRole AS 'Type',
				ipoadtt.RspbSeqnTypeId AS 'RspbSeqnTypeId',
				mp.MatterPartyDesc  AS 'PartyType'
		FROM @IntdPatiesOrAddnDfdtRspbTempTable ipoadtt 		
		 JOIN ( SELECT dbo.UDF_CORR_PARTY_NAME(MP.PARTY_ROLE_ID) CorrespondenceMatterPartyName, 
					PR.PARTY_ROLE_ID AS PartyRoleTypeId,prt.PARTY_ROLE_TYPE_DESC MatterPartyRole, MPT.MATTER_PARTY_TYPE_DESC MatterPartyDesc, MP.MATTER_PARTY_ID
						FROM APP.T_MATTER_PARTY MP
						JOIN LKP.T_MATTER_PARTY_TYPE AS MPT  ON MP.MATTER_PARTY_TYPE_ID = MPT.MATTER_PARTY_TYPE_ID
						JOIN APP.T_PARTY_ROLE      (nolock)    AS PR   ON MP.PARTY_ROLE_ID = PR.PARTY_ROLE_ID
						JOIN LKP.T_PARTY_ROLE_TYPE   (nolock)  AS PRT  ON PRT.PARTY_ROLE_TYPE_ID = PR.PARTY_ROLE_TYPE_ID
		  ) mp on mp.MATTER_PARTY_ID = ipoadtt.MatterPartyId
	
	ELSE --DRAFT 
		BEGIN
		INSERT INTO @IntdPatiesOrAddnDfdtRspb(CorrespondenceMatterPartyName , MatterPartyRole , PartyRoleTypeId , MatterPartyDesc, MatterPartyId)
			(SELECT CorrespondenceMatterPartyName, MatterPartyRole, PartyRoleTypeId, MatterPartyDesc, MatterPartyId
			FROM dbo.udf_get_parties_for_matter(@intClaimId,2,2, default)
			WHERE PartyRoleTypeId IN (13,24,37,202)
			UNION 
			SELECT CorrespondenceMatterPartyName, MatterPartyRole, PartyRoleTypeId, MatterPartyDesc, MatterPartyId
			FROM dbo.udf_get_parties_for_matter(@intClaimId,2,5, default) 
			WHERE PartyRoleTypeId IN (13,24,37,202))

		SELECT IPOADR.MatterPartyId AS 'MatterPartyId',
			IPOADR.PartyRoleTypeId AS 'PartyRoleTypeId',
			IPOADR.CorrespondenceMatterPartyName AS 'Name',
			IPOADR.MatterPartyRole AS 'Type',
			ipoadtt.RspbSeqnTypeId AS 'RspbSeqnTypeId',
			IPOADR.MatterPartyDesc AS 'PartyType'
		FROM @IntdPatiesOrAddnDfdtRspbTempTable ipoadtt 
		Right JOIN @IntdPatiesOrAddnDfdtRspb IPOADR ON IPOADR.MatterPartyId = ipoadtt.MatterPartyId		
		
	END 
	


		--RETRIEVING OLDEST NOTICE FILE DATE		
		SELECT TOP	1 @dateNoticeFileDate = ISNULL(TUN.DT_PRCSD, UPDATE_DATE)
		FROM APP.T_UEGF_NOTICE TUN
		WHERE TUN.CLAIM_ID = @intClaimId AND TUN.UEGF_STATUS_TYPE_ID = 1 -- 1= Accepted
		ORDER BY TUN.DT_PRCSD

		SELECT @dateDateOfInjury = Col.value('@DateOfInjury', 'date') FROM @xmlHist.nodes('/turd') AS Data(Col)
		--Reading DOI
		IF @dateDateOfInjury IS NULL
			SELECT @dateDateOfInjury = tc.INJURY_DT
			FROM APP.T_CLAIM tc
			WHERE (tc.CLAIM_ID = @intClaimId)

		SELECT
			 Col.value('@DisputeId', 'int') AS DisputeId
			,@intClaimId AS ClaimId
			,Col.value('@HideReportingDetails', 'int') AS HideReportingDetails
			,Col.value('@EditPermission', 'int') AS EditPermission
			,@intWCABAppealFlag AS WCABAppealFlag
			,Col.value('@UegfRptnDetsId', 'int') AS UEGFRptnDetsId,
			@dateDateOfInjury AS DateOfInjury,
			Col.value('@DateOfDeath', 'date') AS	DateOfDeath,
			Col.value('@MedicalIndemnityId', 'int') AS MedicalIndemnityId,
			Col.value('@InjuryDesc', 'varchar(1000)') AS InjuryDesc,
			Col.value('@AvgWeeklyWage', 'MONEY') AS AvgWeeklyWage,
			Col.value('@CompRate', 'MONEY') AS CompRate,	
			Col.value('@SpecificLossFlag', 'bit') AS SpecificLossFlag,
			Col.value('@SpecificLossWeeks', 'numeric') AS SpecificLossWeeks,
			Col.value('@HealingPeriodFlag', 'bit') AS HealingPeriodFlag,
			Col.value('@HealingPeriodWeeks', 'numeric') AS HealingPeriodWeeks,
			Col.value('@LitigationCost', 'MONEY') AS LitigationCost,
			Col.value('@InterstFlag', 'bit') AS InterstFlag,
			@dateNoticeFileDate AS	NtceFileDate,
			Col.value('@NtceFile45DaysFlag', 'bit') AS NtceFile45DaysFlag,
			Col.value('@UEGFPaymentStartDate', 'date') AS UEGFPaymentStartDate,
			Col.value('@EmployeeStatusTypeId', 'int') AS EmployeeStatusTypeId,
			Col.value('@AvgWeeklyWageDeterminationFlag', 'bit') AS AvgWeeklyWageDeterminationFlag,
			Col.value('@OtherWageDetermination', 'varchar(100)') AS OtherWageDetermination,
			Col.value('@StipulationOrCandR', 'int') AS StipulationOrCandR,
			Col.value('@UEGFStipulationFlag', 'bit') AS UEGFStipulationFlag,
			Col.value('@CRRptnTypeId', 'int') AS CRRptnTypeId,
			ISNULL(Col.value('@CompromiseRptnTypeId', 'int'), @intCnRDecisionId) AS CompromiseRptnTypeId,
			ISNULL(Col.value('@CompromiseMedicalTypeId', 'int'), @intCnRMedicalId) AS CompromiseMedicalTypeId,
			ISNULL(Col.value('@TotalCRAmount', 'MONEY'), @moneyTotalCnRAmount) AS TotalCRAmount,
			ISNULL(Col.value('@TotalFutureMedicalAmount', 'MONEY'), @moneyFutureMedical) AS TotalFutureMedicalAmount,
			ISNULL(Col.value('@MedicareAsideAmount', 'MONEY'), @moneyMedicareSetAsideAmount) AS MedicareAsideAmount,
			ISNULL(Col.value('@ClaimantRepresentedFlagId', 'int'), @intIsClaimantEmployeeRepresentedId) AS ClaimantRepresentedFlagId
			--@intCnRDecisionId INT, @moneyAvgWeeklyWage MONEY = NULL, @moneyCompRate MONEY = NULL, @moneyTotalCnRAmount MONEY = NULL, @moneyFutureMedical MONEY = NULL, @moneyMedicareSetAsideAmount MONEY = NULL, @intCnRMedicalId INT, @intIsClaimantEmployeeRepresentedId
			,@pintHistId AS HistId
			,@intFrmHistId AS FrmRptngHistId
		FROM @xmlHist.nodes('/turd') AS Data(Col)

		INSERT INTO @ReportingDetailCRSubDecisionTempTable
		(
		    UEGFReportingDetailCRSubDecisionId,
		    UEGFreportingDetailId,
		    CompromiseAndReleaseDecisionSubTypeId
		)
		SELECT Col.value('@UEGFReportingDetailCRSubDecisionId', 'INT') AS 'UEGFReportingDetailCRSubDecisionId', Col.value('@UEGFreportingDetailId', 'INT') AS 'UEGFreportingDetailId',
		Col.value('@CompromiseAndReleaseDecisionSubTypeId', 'INT') AS 'CompromiseAndReleaseDecisionSubTypeId'
		FROM @xmlHist.nodes('/turdcsd') AS Data(Col)
		SELECT rdcdtt.UEGFReportingDetailCRSubDecisionId, rdcdtt.UEGFreportingDetailId, CompromiseAndReleaseDecisionSubTypeId FROM @ReportingDetailCRSubDecisionTempTable rdcdtt

		SELECT DBO.UDF_PARTY_NAME(turh.UPDTD_BY) AS 'UpdatedBy',
					turh.UPDATE_DATE AS 'UpdatedDate'
			FROM APP.T_UEGF_RPTNG_HIST turh WHERE turh.UEGF_RPTNG_HIST_ID = @pintHistId

			

END