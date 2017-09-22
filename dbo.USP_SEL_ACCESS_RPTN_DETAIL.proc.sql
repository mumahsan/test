
/****** Object:  StoredProcedure [dbo].[USP_SEL_RPTN_DETAIL]    Script Date: 4/20/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

ALTER PROCEDURE [dbo].[USP_SEL_ACCESS_RPTN_DETAIL]
	
	@pintClaimId INT, 
	@pintPartyRoleID INT, 
	@pintProgramAreaID INT,
	@pintEditPermission INT  OUTPUT,
	@pintHideReportingDetails INT  OUTPUT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].[USP_SEL_ACCESS_RPTN_DETAIL]
 * Author:   c-mahsan
 * Date:     06 APR 2017
 *
 * Purpose/Description: 
 *     Return Edit and View access to the reporting details for the current dispute id for the given party role id 
 *
 * Parameters:
 *     @pintDsptId	Dispute IDENTIFIER 
 *
 * Return:
 *     APP.T_RPTNG_RPTNG_DETAIL, APP.T_DSPT_PETITN, APP.T_UEGF_INDEMNITY_PMT, APP.T_UEGF_RPTNG_WAGE_DETER, APP.T_UEGF_RPTNG_DETER_ISSUE, APP.T_UEGF_RPTNG_INTD_PARTY_RESPBLT
 *
 * Table and Alias Definitions:
 *     T_RPTNG_RPTNG_DETAIL , CLAIM_ID
 *  
 * Called Programs:
 *     NONE
 *
 *********************************************************************/	
 
 SET NOCOUNT ON;
	
	DECLARE	@intPartyRoleTypeId AS INT
			, @intExternalFlag AS INT = 0 		
			,@isUEGFClaim INT 
			,@intOpenDisputes INT, @intOpenAppeals INT, @intCloseAppeals INT

			SELECT @pintEditPermission =0, 	@pintHideReportingDetails = 0 
			exec USP_SEL_CLAIM_IS_UEGF   @pintClaimId,NULL,NULL,NULL,@isUEGFClaim  OUTPUT
						
		
			IF  @isUEGFClaim <> 1 
				SELECT @pintHideReportingDetails = 1 

			IF  @isUEGFClaim = 1
			BEGIN 
			
				SELECT @intPartyRoleTypeId = PR.PARTY_ROLE_TYPE_ID 
				,@intExternalFlag = PRT.EXTNL_FLAG
				FROM APP.T_PARTY_ROLE PR
				JOIN LKP.T_PARTY_ROLE_TYPE PRT ON PRT.PARTY_ROLE_TYPE_ID = PR.PARTY_ROLE_TYPE_ID
				WHERE PR.PARTY_ROLE_ID = @pintPartyRoleID
							
				-- if party role type id is 2, 37 38 external 
				-- Dispute without a Appeal Open or Dispute remanded. ( dispute open after appeal filed date) 
				SELECT @intOpenDisputes= COUNT(1) 			
				FROM APP.T_DSPT D 
				JOIN APP.T_DSPT_STATUS_HIST DSH ON DSH.DSPT_ID = D.DSPT_ID AND DSH.STATUS_TO_DT IS NULL 
				LEFT JOIN APP.T_APPEAL_CASE AC ON AC.DSPT_ID = D.DSPT_ID AND AC.PETITN_FLAG = 0 
				 AND CAST(AC.CREATE_DATE AS DATETIME) + CAST(AC.CREATE_TIME AS DATETIME)  >= CAST(DSH.STATUS_FROM_DT AS DATETIME) + CAST(DSH.CREATE_TIME AS DATETIME) 
				WHERE  AC.DSPT_ID IS  NULL AND D.CLAIM_ID =@pintClaimId

				
				--SELECT * FROM LKP.T_OPON_STATUS_TYPE
				--Appeal with opinion published
				SELECT @intCloseAppeals = COUNT(1) 
				FROM APP.T_APPEAL_CASE AC 
				JOIN ( SELECT AO.APPEAL_CASE_ID FROM  APP.T_APPEAL_OPON AO 
				JOIN APP.T_OPON O ON O.OPON_ID = AO.OPON_ID WHERE O.OPON_STATUS_TYPE_ID IN (2,4,9) ) AO ON AO.APPEAL_CASE_ID = AC.APPEAL_CASE_ID
				WHERE AC.CLAIM_ID = @pintClaimId 


				--OpenAppeal
				SELECT @intOpenAppeals = COUNT(1) 
				FROM APP.T_APPEAL_CASE AC 
				LEFT JOIN ( SELECT AO.APPEAL_CASE_ID FROM  APP.T_APPEAL_OPON AO 
				JOIN APP.T_OPON O ON O.OPON_ID = AO.OPON_ID WHERE O.OPON_STATUS_TYPE_ID IN (2,4,9) ) AO ON AO.APPEAL_CASE_ID = AC.APPEAL_CASE_ID
				WHERE AC.Claim_id = @pintClaimId and AO.APPEAL_CASE_ID IS NULL

				--select @intOpenDisputes 'opendispute', @intOpenAppeals 'openappeal'

				IF @intExternalFlag  = 1 
				BEGIN
					--select @intPartyRoleTypeId 'partyroletype'
					SELECT @pintHideReportingDetails = 1 
					--FOR ATTORNEY, CHECK IF THE PARTY IS  FUND ATTORNEY
					--IF TPA USER OR TPA ADMIN, CHECK IF THIS IS UEGF TPA
					IF ( @intPartyRoleTypeId= 2 AND EXISTS ( SELECT * FROM dbo.[UDF_GET_UEGF_ATT](@pintClaimId) WHERE PartyRoleId = @pintPartyRoleID))
					OR (@intPartyRoleTypeId IN ( 39, 38) AND EXISTS ( SELECT * FROM DBO.[UDF_GET_UEGF_PARTIES]() WHERE PARTY_ROLE_ID  = @pintPartyRoleID))
					BEGIN 				
						SELECT @pintHideReportingDetails = 0 	
					END 

				END
				ELSE
				BEGIN 

	
				-- if party role type id is internal continue		

					--IF PROGRAM AREA IS 3 = WCOA. THEN CHECK IF THE USER CAN EDIT 
					--HE/SHE CAN EDIT IF THEY ARE Litigating Judge, Litigating Judge's Judge Secretary, Litigating Judge's Judge Manager, Litigating Judge's Field Office Supervisor, Litigating Judge's Administrative Officer and the WCOA Director
					IF  @pintProgramAreaID = 3 AND  @intOpenDisputes > 0  
					BEGIN 
						SELECT @pintEditPermission = 1 
					END 	
			
					--WCAB Staff Administrators, assigned Commissi oner, assigned Field Office Staff, assigned WCAB Commissioner's Secretary, 
					--assigned Opinion Writer, Opinion Writer Manager, and Legal Supervisor
					IF (@pintProgramAreaID = 2 AND --WCAB
								(	
									EXISTS ( SELECT * FROM APP.T_APPEAL_CASE_CMMSNER TACC
												JOIN APP.T_APPEAL_CASE TAC ON TAC.APPEAL_CASE_ID = TACC.APPEAL_CASE_ID	
													WHERE TACC.CMMSNER_ID	= @pintPartyRoleID AND TACC.DT_TO IS NULL AND TAC.claim_id =   @pintClaimId ) --  assigned Commissioner
									OR EXISTS ( select * from app.t_party_role where party_role_id = @pintpartyRoleId and MANAGE_WRITER_FLAG = 1) --Opinion manager has access to edit 
									OR EXISTS ( SELECT * 
												FROM APP.T_APPEAL_CASE_CMMSNER TACC
												JOIN APP.T_APPEAL_CASE TAC ON TAC.APPEAL_CASE_ID = TACC.APPEAL_CASE_ID  AND TACC.DT_TO IS NULL
												JOIN APP.T_WCAIS_ORGN_STAFF J_WOS  ON J_WOS.STAFF_ID =TACC.CMMSNER_ID
												JOIN APP.T_WCAIS_ORGN J_W ON J_W.WCAIS_ORGN_ID = J_WOS.WCAIS_ORGN_ID AND J_W.WCAIS_ORGN_TYPE_ID IN (8, 10)
												JOIN APP.T_WCAIS_ORGN_STAFF P_WOS  ON  P_WOS.WCAIS_ORGN_ID = J_W.WCAIS_ORGN_ID
												JOIN APP.T_PARTY_ROLE PR ON PR.PARTY_ROLE_ID = P_WOS.STAFF_ID AND PR.PARTY_ROLE_TYPE_ID IN ( 47 , 49, 51) AND PR.PARTY_ROLE_ID = @pintPartyRoleID
												WHERE TAC.claim_ID = @pintClaimId AND J_WOS.DT_TO IS NOT NULL AND P_WOS.DT_TO IS NOT NULL
												)  --47  assigned Field Office Staff, 49 assigned Opinion Writer
									-- Finding the assigned opoion writer
									OR EXISTS (SELECT * 
												FROM APP.T_APPEAL_CASE TAC
												INNER JOIN	APP.T_APPEAL_OPON TAO ON TAO.APPEAL_CASE_ID = TAC.APPEAL_CASE_ID
												INNER JOIN APP.T_OPON_WRITER TOW ON TAO.OPON_ID = TOW.OPON_ID 
												WHERE TAC.CLAIM_ID = @pintClaimId AND TOW.OPON_WrITER_ID = @pintPartyRoleId)
									OR (  @intPartyRoleTypeId = 51 -- wcab staff administrator
											AND EXISTS ( SELECT * 
														FROM APP.T_APPEAL_CASE AC
														INNER JOIN APP.T_APPEAL_PETITN AP ON AP.APPEAL_CASE_ID = AC.APPEAL_CASE_ID
														WHERE ac.CLAIM_ID = @pintClaimId AND APPEAL_PETITN_STATUS_TYPE_ID IN (2,5)) -- 2 = APPEAL ACCEPTED, 5 = PETITN ACCEPTED
										)							
								)
							)
						BEGIN 
							SELECT @pintEditPermission = 1 
						END	
				
						--the BWC OCC Chief role will have edit access
						--137 = BWC OCC Chief
						IF (@pintProgramAreaID = 1
							AND EXISTS (SELECT APP.T_PARTY_ROLE.PARTY_ROLE_ID FROM APP.T_PARTY_ROLE WHERE PARTY_ROLE_ID = @PINTPARTYROLEID AND APP.T_PARTY_ROLE.PARTY_ROLE_TYPE_ID = 137)													
							AND @intCloseAppeals > 0 
							)
			
						BEGIN 
							SELECT @pintEditPermission = 1 
						END				
		
						--Access control logic
						--IF the dispute status is open (not close), BWC and WCAB users can see only snapshots and cannot see current details
						--If No appeal or petition is filed on this dispute and dispute is close then WCAB users can only see snaphots and cannot see current details
						-- dispute status 2 mean Closed
						--SELECT * FROM lkp.T_DSPT_STATUS_TYPE tdst	
						-- IF BWC users and dispute is not closed the hide the details else show
						-- BWC users cannot edit any reporting details
						--DEF-228874 BWC roles can see the Reporting Details for Remand Dispute before Decision is circulated
		
						IF ((@pintProgramAreaID = 1 OR @pintProgramAreaID = 2) 
						AND (NOT EXISTS (SELECT * FROM APP.T_UEGF_RPTNG_HIST WHERE CLAIM_ID = @pintClaimId AND RPTNG_HIST_STATUS_ID = 2) ))
						BEGIN
												SELECT	@pintHideReportingDetails = 1
						END

						
					END 
						-- if uegf tpa then give access to view the reporting details.

		END
		 

END