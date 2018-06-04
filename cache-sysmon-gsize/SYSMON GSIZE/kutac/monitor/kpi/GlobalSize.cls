/// prepare KPI for displaying Global sizes in a selected database
/// please note, the query uses fast flag to just count # of blocks rather then evaluating true size, which is very slow on large datasets (can last hours)
Class kutac.monitor.kpi.GlobalSize Extends %DeepSee.KPI
{

Parameter DOMAIN = "sysmon";

Parameter RESOURCE;

/// This XData definition defines the KPI.
XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi xmlns="http://www.intersystems.com/deepsee/kpi"
 name="SYSMON Global Sizes" sourceType="manual"
 caption=""
>
 <filter name="Database" />
 <filter name="SystemGlobals" displayName="System globals?" valueList="0,1" defaultValue="0" displayList="false,true" />
 <filter name="Top" defaultValue="0" />

 <property name="GlobalSizeAlloc" displayName="Global Size Alloc (MB)" columnNo="1" />
 <!--<property name="GlobalSizeUsed" displayName="Global Size Used (MB)" columnNo="2" />-->

</kpi>
}

/// Get data for this KPI manually.
/// This is implemented by subclasses that provide manual data.
Method %OnExecute() As %Status [ PublicList = tmp ]
{
	Set tSC = $$$OK
	#dim tCounter=0
	new tmp
	Try {
		set tStatement=##class(%SQL.Statement).%New()
		$$$THROWONERROR(tSC,tStatement.%PrepareClassQuery("%SYS.GlobalQuery","Size"))
		if $isobject(..%filterValues) {
			set tDatabase=..%filterValues.Database	
		} else {
			set tDatabase=$zu(12)	
		}
		set tShowAll=(+..%filterValues.Top=0)
		set tNoShowUsedSize=1
		#dim tResult as %SQL.StatementResult=tStatement.%Execute(tDatabase,,,..%filterValues.SystemGlobals,,tNoShowUsedSize)
		while tResult.%Next() {
			if $i(tCounter)
			if tShowAll {
				set ..%seriesNames(tCounter)=tResult.%GetData(1)
				set ..%data(tCounter,"GlobalSizeAlloc")=tResult.%GetData(2)
				//set ..%data(tCounter,"GlobalSizeUsed")=tResult.%GetData(3)	
			} else {
				set tmp(+tResult.%GetData(2),tResult.%GetData(1))=""
			}
		}
		set ..%seriesCount=tCounter
		
		
		if 'tShowAll {
			set tMaxCnt=$s(..%filterValues.Top>tCounter:tCounter,1:..%filterValues.Top)
			set tCounter2=0
			set tNode=$q(tmp(""),-1)
			set ..%seriesNames(1)=$qs(tNode,2)
			set ..%data(1,"GlobalSizeAlloc")=$qs(tNode,1)
			for i=2:1:tMaxCnt {
				set tNode=$q(@tNode,-1)
				set ..%seriesNames(i)=$qs(tNode,2)
				set ..%data(i,"GlobalSizeAlloc")=$qs(tNode,1)
			}
			set ..%seriesCount=tMaxCnt
		}
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	k tmp
	Quit tSC
}

/// Callback to get additional members for a KPI filter.
/// This takes the form:<br/>
/// pMembers($I(pMembers))=$LB(text,value)<br/>
/// <var>pSearchKey</var> is the search key entered by the user, if applicable.<br/>
/// <var>pFilterValues</var> is an array of all current filter values.<br/>
ClassMethod %OnGetFilterMembers(pFilter As %String, Output pMembers As %List, pSearchKey As %String = "", pDataSourceName As %String = "", ByRef pFilterValues As %String) As %Status
{
	#dim tSC as %Status = $$$OK
	#dim e as %Exception.AbstractException
	try {
		if pFilter="Database" {
			set tStatement=##class(%SQL.Statement).%New()
			$$$THROWONERROR(tSC,tStatement.%PrepareClassQuery("Config.Databases","List"))
			#dim tResult as %SQL.StatementResult=tStatement.%Execute()
			while tResult.%Next() {
				set pMembers($i(pMembers))=$lb(tResult.%Get("Name"),tResult.%Get("Directory"))
			}
		}
	} catch (e) {
		set tSC=$$$ADDSC(tSC,e.AsStatus())
	}
	return tSC
}

}

