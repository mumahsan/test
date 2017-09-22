/****** Object:  StoredProcedure dbo.USP_SEL_RPTN_DETAIL_MOST_RECENT_SNPSHT    Script Date: 4/20/2017 7:03:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE dbo.USP_SEL_RPTN_DETAIL_MOST_RECENT_SNPSHT
	  @pintClaimId INT
	 ,@pintPartyRoleID INT
	 ,@pintProgramAreaID INT
	 ,@pintCrtdUpdtdBy INT
	 ,@pintCrtdUpdtdByOffice INT
AS
/*********************************************************************
 * Name:    [dbo].[USP_SEL_RPTN_DETAIL_MOST_RECENT_SNPSHT]
 * Author:   c-mahsan
 * Date:     24 APR 2017
 *
 * Purpose/Description:
 *     Retrieve History Identification Number by the dispute number
 *
 * Parameters:
 *     @pintDsptId	Unique Dispute Identifier
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
 
 BEGIN
	DECLARE @UEGFRptngHistId AS INT, @intPrevDsptId INT
	SET NOCOUNT ON;
	DECLARE	 @intDraftHistoryId INT, @dtCurrentDate DATETIME = GETDATE()
		

		

		--Get the Snapshot Hist Id
		SELECT TOP 1 @intDraftHistoryId= URH.UEGF_RPTNG_HIST_ID FROM APP.T_UEGF_RPTNG_HIST URH
		WHERE URH.RPTNG_HIST_STATUS_ID = 1 AND URH.CLAIM_ID = @pintClaimId AND PROG_AREA_ID = @pintProgramAreaID

		--Update the draft status to deleted
		UPDATE TURH SET RPTNG_HIST_STATUS_ID = 3,-- 3 = deleted
						UPDTD_BY = @pintCrtdUpdtdBy, UPDATE_DATE = @dtCurrentDate, UPDATE_TIME = @dtCurrentDate, UPDTD_BY_OFFICE= @pintCrtdUpdtdByOffice, 
						STAFF_ID = @pintCrtdUpdtdBy
		FROM APP.T_UEGF_RPTNG_HIST TURH
		WHERE TURH.UEGF_RPTNG_HIST_ID = @intDraftHistoryId
				
		--GET THE LATEST SNAPSHOT
		EXEC dbo.USP_SEL_RPTN_DETAIL @pintClaimId, @pintPartyRoleID, @pintProgramAreaID, @pintCrtdUpdtdBy, @pintCrtdUpdtdByOffice

END
