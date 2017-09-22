CREATE PROCEDURE [dbo].[USP_SEL_RPTN_DETAIL_XML]    
 @pintDisputeId INT = NULL,    
 @xml XML OUTPUT    
AS    
BEGIN     
/*********************************************************************    
 * Name:    [dbo].[USP_SEL_RPTN_DETAIL_XML]    
 * Author:   c-mahsan    
 * Date:     06 APR 2017    
 *    
 * Purpose/Description:    
 *     Retrieve record relating to the dispute number    
 *    
 * Parameters:    
 *     @pintDisputeId Dispute IDENTIFIER    
 *    
 * Return:    
 *     APP.T_UEGF_RPTNG_DETAIL, APP.T_DSPT_PETITN, APP.T_UEGF_INDEMNITY_PMT, APP.T_UEGF_RPTNG_WAGE_DETER, APP.T_UEGF_RPTNG_DETER_ISSUE, APP.T_UEGF_RPTNG_INTD_PARTY_RESPBLT    
 *    
 * Table and Alias Definitions:    
 *     NONE     
 *      
 * Called Programs:    
 *     NONE    
 * NO USED ANY WHERE     
 *    
 *********************************************************************/     
     
 SET NOCOUNT ON;    
     
 DECLARE @intUEGFRptnDetsId AS INT, @intClaimId INT    
     
 SELECT @intClaimId = td.CLAIM_ID FROM APP.T_DSPT td WHERE td.DSPT_ID = @pintDisputeId    
    
 IF EXISTS ( SELECT tc.CLAIM_ID    
  FROM APP.T_CLAIM tc    
  INNER JOIN LKP.T_CLAIM_CAT_TYPE tcct ON tcct.CLAIM_CAT_TYPE_ID = tc.CLAIM_CAT_TYPE_ID    
  WHERE tc.CLAIM_CAT_TYPE_ID = 7    
  AND tc.CLAIM_ID = @intClaimId    
 )    
 BEGIN    
  --Reading value for parameter @pintDisputeId    
  SELECT top 1 @intUEGFRptnDetsId = turd.UEGF_RPTNG_DETAIL_ID    
  FROM APP.T_UEGF_RPTNG_DETAIL turd    
  WHERE turd.CLAIM_ID = @intClaimId  
  order by turd.UEGF_RPTNG_DETAIL_ID desc   
    
  DECLARE @PetitionDispositionTempTable TABLE(DisputePetitionId INT, DsptPetitnTypeId INT, PetitionType nvarchar(500), DispositionTypeId int, OponDispnTypeId int)    
  INSERT INTO @PetitionDispositionTempTable    
  (    
      DisputePetitionId, DsptPetitnTypeId, PetitionType, DispositionTypeId, OponDispnTypeId    
  )    
  SELECT tdp.DSPT_PETITN_ID AS 'DisputePetitionId' ,tdpt.DSPT_PETITN_TYPE_ID AS 'DsptPetitnTypeId'     
   ,tdpt.DSPT_PETITN_TYPE_DESC +'('+CONVERT(varchar(10), tdp.PETITN_FILED_DT, 101)+')' AS 'PetitionType',     
   tdp.DSPT_DISPN_TYPE_ID AS 'DispositionTypeId', tdp.OPON_DISPN_TYPE_ID AS 'OponDispnTypeId'    
  FROM APP.T_DSPT_PETITN tdp INNER JOIN LKP.T_DSPT_PETITN_TYPE tdpt ON tdpt.DSPT_PETITN_TYPE_ID = tdp.DSPT_PETITN_TYPE_ID    
  WHERE tdp.CLAIM_ID = @intClaimId AND tdp.DSPT_ID IS NOT NULL    
    
  DECLARE @DsptPetnXml XML = (    
   SELECT DisputePetitionId, DsptPetitnTypeId, PetitionType, DispositionTypeId, OponDispnTypeId FROM @PetitionDispositionTempTable tdp    
  FOR XML AUTO)    
    
  DECLARE @IndmPaytXml XML = (    
  SELECT tuip.UEGF_INDEMNITY_PMT_ID AS 'UEGFIndemnityPaymentId', tuip.UEGF_RPTNG_DETAIL_ID AS 'UEGFRptnDetsId',    
   tuip.DSBLTY_TYPE_ID AS 'DisablityTypeId',    
  CASE WHEN tuip.DSBLTY_TYPE_ID = 1 THEN 'TTD'    
    WHEN tuip.DSBLTY_TYPE_ID = 2 THEN 'TPD'    
  END AS 'DisablityTypeDesc', tuip.PMT_START_DT AS 'PaymentStartDate', tuip.PMT_END_DT AS 'PaymentEndDate'    
  FROM APP.T_UEGF_INDEMNITY_PMT tuip    
  WHERE tuip.UEGF_RPTNG_DETAIL_ID = @intUEGFRptnDetsId    
  FOR XML AUTO)    
    
  DECLARE @RptnWageDeterXml XML = (    
  SELECT tudwd.UEGF_RPTNG_DETAIL_ID AS 'UEGFRptnDetsId', tudwd.UEGF_RPTNG_WAGE_DETER_ID AS 'UEGFRptnWageDeterId',     
   tudwd.WAGE_DETER_TYPE_ID AS 'WageDeterminationTypeId', twdt.WAGE_DETER_TYPE_DESC AS 'WageDeterminationTypeDesc'    
   FROM APP.T_UEGF_RPTNG_WAGE_DETER tudwd INNER JOIN LKP.T_WAGE_DETER_TYPE twdt ON twdt.WAGE_DETER_TYPE_ID = tudwd.WAGE_DETER_TYPE_ID    
  WHERE tudwd.UEGF_RPTNG_DETAIL_ID = @intUEGFRptnDetsId    
  FOR XML AUTO)    
    
  DECLARE @TaxPaidEvidXml AS XML = (    
  SELECT turtpe.UEGF_RPTNG_TAX_PAID_EVID_ID AS 'RptngTaxPaidEvidId', turtpe.UEGF_RPTNG_DETAIL_ID AS 'RptngDetailId', turtpe.TAX_PAID_EVID_ID AS 'TaxPaidEvidId'     
  FROM APP.T_UEGF_RPTNG_TAX_PAID_EVID turtpe    
  WHERE turtpe.UEGF_RPTNG_DETAIL_ID = @intUEGFRptnDetsId    
  FOR XML AUTO)    
    
  DECLARE @RptnDeterIssueXml XML = (    
  SELECT tuddi.UEGF_RPTNG_DETAIL_ID AS 'UEGFRptnDetsId', tuddi.DETER_ISSUE_TYPE_ID AS 'DeterminaitionIssueTypeId',     
   tdit.DETER_ISSUE_TYPE_DESC AS 'DeterminaitonIssueTypeDesc'    
   FROM APP.T_UEGF_RPTNG_DETER_ISSUE tuddi INNER JOIN LKP.T_DETER_ISSUE_TYPE tdit ON tdit.DETER_ISSUE_TYPE_ID = tuddi.DETER_ISSUE_TYPE_ID    
  WHERE tuddi.UEGF_RPTNG_DETAIL_ID = @intUEGFRptnDetsId    
  FOR XML AUTO)    
    
  DECLARE @IntdPartXml XML = (    
  SELECT turipr.RESPBLTY_SEQ_TYPE_ID AS 'RspbSeqnTypeId',  turipr.MATTER_PARTY_ID AS 'MatterPartyId'    
  FROM APP.T_UEGF_RPTNG_INTD_PARTY_RESPBLT turipr    
  WHERE turipr.UEGF_RPTNG_DETAIL_ID = @intUEGFRptnDetsId    
  FOR XML AUTO)    
    
  DECLARE @RptnDetailXml AS XML = (    
     
   SELECT    
   @pintDisputeId AS 'DisputeId', @intClaimId AS 'ClaimId', turd.INJURY_DT AS 'DateOfInjury', turd.DEATH_DT AS 'DateOfDeath',     
   turd.MED_INDEMNITY_COMP_TYPE_ID AS 'MedicalIndemnityId', turd.INJURY_DESC AS 'InjuryDesc', turd.AVG_WEEKLY_WAGE AS 'AvgWeeklyWage',    
   turd.COMP_RATE AS 'CompRate', turd.SPFC_LOSS_FLAG AS 'SpecificLossFlag', turd.SPFC_LOSS_WEEKS AS 'SpecificLossWeeks',    
   turd.HEALING_PERIOD_FLAG AS 'HealingPeriodFlag', turd.HEALING_PERIOD_WEEKS AS 'HealingPeriodWeeks', turd.LITGN_COST AS 'LitigationCost',    
   turd.INT_FLAG AS 'InterstFlag', turd.NOTICE_FILED_DT AS 'NtceFileDate', turd.NOTICE_FILED_45_DAYS_FLAG AS 'NtceFile45DaysFlag',    
   turd.UEGF_PMT_START_DT AS 'UEGFPaymentStartDate', turd.EMPL_STATUS_TYPE_ID AS 'EmployeeStatusTypeId',     
   turd.AVG_WEEKLY_WAGE_DETER_FLAG AS 'AvgWeeklyWageDeterminationFlag', turd.OTHER_WAGE_DETER AS 'OtherWageDetermination',    
   --turd.TAX_PAID_EVID_FLAG AS 'TaxPaidEvidenceFlag', turd.EE_FLAG AS 'EEFlag', turd.ER_FLAG AS 'ERFlag',    
    case when turd.STIPN_FLAG = 1 then 1  
    when turd.CR_FLAG = 1 then 2 else null end as 'StipulationOrCandR', turd.UEGF_STIP_FLAG AS 'UEGFStipulationFlag',    
   turd.CR_DECN_TYPE_ID AS 'CRRptnTypeId', turd.COMPRMS_DECN_TYPE_ID AS 'CompromiseRptnTypeId',    
   turd.COMPRMS_MED_TYPE_ID AS 'CompromiseMedicalTypeId', turd.TOTAL_CR_AMOUNT AS 'TotalCRAmount', turd.TOTAL_FUTURE_MED_AMOUNT AS 'TotalFutureMedicalAmount',    
   turd.MDCARE_ASIDE_AMOUNT AS 'MedicareAsideAmount', case turd.CLMT_REPRTED_YES_NO_ID when 1 then 1 when 0 then 2 else null end  AS 'ClaimantRepresentedFlagId', 0 AS 'FrmRptngHistId'   
  FROM APP.T_UEGF_RPTNG_DETAIL turd     
  WHERE turd.CLAIM_ID = @intClaimId  
  and turd.UEGF_RPTNG_DETAIL_ID     = @intUEGFRptnDetsId 
  FOR XML AUTO)    
    
  DECLARE @ReportingDetailCRSubDecisionXml AS XML = (    
   SELECT turdcsd.UEGF_RPTNG_DETAIL_CR_SUB_DECN_ID AS 'UEGFReportingDetailCRSubDecisionId', turdcsd.UEGF_RPTNG_DETAIL_ID AS 'UEGFreportingDetailId', turdcsd.COMPRMS_RLS_DECN_SUB_TYPE_ID AS 'CompromiseAndReleaseDecisionSubTypeId'    
   FROM APP.T_UEGF_RPTNG_DETAIL_CR_SUB_DEC turdcsd    
   WHERE turdcsd.UEGF_RPTNG_DETAIL_ID = @intUEGFRptnDetsId    
  FOR XML AUTO)    
    
  --SET @xml =    
  -- cast(@DsptPetnXml as nvarchar(max))     
  -- + cast(@IndmPaytXml as nvarchar(max))     
  -- + cast(@RptnWageDeterXml as nvarchar(max))     
   --+ cast(@RptnDeterIssueXml as nvarchar(max))     
   --+ cast(@IntdPartXml as nvarchar(max))     
   --+ cast(@RptnDetailXml as nvarchar(max))    
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
 END    
END  
  