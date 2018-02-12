<#

    .COPYRIGHT
    Copyright (c) Office Center Hønefoss AS. All rights reserved. Based on code from Jan Egil Ring (Crayon). Licensed under the MIT license.
    See https://github.com/officecenter/Autotask/blob/master/LICENSE.md for license information.

#>
Function Get-AtwsCustomEntity {
  <#
      .SYNOPSIS
      This function get one or more Queues from the Autotask Web Services API.
      .DESCRIPTION
      This function gets all queue names from Autotask through the Ticket fieldinfo and filters them using the parameters you specify. By default the function returns any objects with properties that are Equal (-eq) to the value of the parameter. To give you more flexibility you can modify the operator by using -NotEquals [ParameterName[]], -LessThan [ParameterName[]] and so on.

      Possible operators for all parameters are:
      -NotEquals
      -GreaterThan
      -GreaterThanOrEqual
      -LessThan
      -LessThanOrEquals 

      Additional operators for QueueName are:
      -Like (supports * as wildcard)
      -NotLike

      .INPUTS
      Nothing. This function only takes parameters.
      .OUTPUTS
      [PSCustomObject]. This function outputs Autotask queues as custom Powershell objects.
      .EXAMPLE
      Get-AtwsQueue -Id 0
      Returns the object with Id 0, if any.
      .EXAMPLE
      Get-AtwsQueue -QueueName SomeName
      Returns the object with QueueName 'SomeName', if any.
      .EXAMPLE
      Get-AtwsQueue -QueueName 'Some Name'
      Returns the object with QueueName 'Some Name', if any.
      .EXAMPLE
      Get-AtwsQueue -QueueName 'Some Name' -NotEquals QueueName
      Returns any objects with a QueueName that is NOT equal to 'Some Name', if any.
      .EXAMPLE
      Get-AtwsQueue -QueueName SomeName* -Like QueueName
      Returns any object with a TaxName that matches the simple pattern 'SomeName*'. Supported wildcards are *.
      .EXAMPLE
      Get-AtwsQueue -QueueName SomeName* -NotLike QueueName
      Returns any object with a QueueName that DOES NOT match the simple pattern 'SomeName*'. Supported wildcards are *.

  #>

  [CmdLetBinding(DefaultParameterSetName = 'Get_All')]
  [OutputType([Autotask.EntityInfo[]], ParameterSetName = 'Get_All')]
  [OutputType([Autotask.EntityInfo[]], ParameterSetName = 'Get_entity')]
  [OutputType([Autotask.Field[]], ParameterSetName = 'Get_fieldinfo')]
      
  Param
  (
    # A filter that limits the number of objects that is returned from the API
    [Parameter(
        Mandatory = $true,
        ValueFromRemainingArguments = $true,
        ParameterSetName = 'Filter'
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $Filter,
    
    # Return all objects in one query
    [Parameter(
        ParameterSetName = 'Get_all'
    )]
    [Switch]
    $All,

    # Entity names
    [Parameter(
        Mandatory = $True,
        ParameterSetName = 'Filter'
    )]
    [Parameter(
        ParameterSetName = 'Get_entity'
    )]
    [ValidateSet('Queue')]
    [String[]]
    $Entity,

    # Queue Name
    [Parameter(
        ParameterSetName = 'Get_fieldinfo'
    )]
    [ValidateSet('Queue')]
    [String]
    $FieldInfo
  )
 
  Begin { 

    Write-Verbose -Message ('{0}: Begin of function' -F $MyInvocation.MyCommand.Name)
    # List of Custom entity names
    $EntityNames = @('Queue')
    $Result = @()
  }

  Process {
    If ($PSCmdlet.ParameterSetName -eq 'Get_all') {
      # Create Autotask.EntityInfo for the custom entities
      Foreach ($Name in $EntityNames) {
        $CustomEntity = New-Object Autotask.EntityInfo
        $CustomEntity.CanQuery = $true
        $CustomEntity.Name = $Name
        $Result += $CustomEntity
      }
    }
    ElseIf ($PSCmdlet.ParameterSetName -eq 'Get_fieldinfo') {
      If ($FieldInfo -eq 'Queue') {
        # Queue Fields
        $QueueNameField = Get-AtwsFieldInfo -Entity 'Ticket' -Connection 'Atws' | Where-Object -FilterScript {$_.Name -eq 'QueueId'}
        $QueueNameField.Name = 'QueueName'
        $QueueNameField.Label = 'Queue Name'
        $Result += $QueueNameField

        # We need our own copy for this field
        $QueueIdField = Get-AtwsFieldInfo -Entity 'Ticket' -Connection 'Atws' | Where-Object -FilterScript {$_.Name -eq 'QueueId'}
        $QueueIdField.Type = 'String'
        $QueueIdField.Length = 200

        # Reverse ID and Label for this field
        # Create all the Entities for Queue at the same time
        $Items = @()
        Foreach ($Item in $QueueIdField.PicklistValues) {
          $Items += New-Object -TypeName PSObject -Property @{
            QueueName = $Item.Label
            Id        = $Item.Value
            IsSystem  = $Item.IsSystem
            IsActive  = $Item.IsActive
          }

          $Label = $Item.Value
          $Value = $Item.Label
          $Item.Label = $Label
          $Item.Value = $Value
        }
        $Result += $QueueIdField

        # Boolean fields
        Foreach ($FieldName in 'IsSystem', 'IsActive') {
          $Item = New-Object Autotask.Field
          $Item.IsQueryable = $True
          $Item.IsReadOnly = $True
          $Item.Name = $FieldName
          $Item.Label = $FieldName
          $Item.Type = 'Boolean'
          $Result += $Item
        }
      }
    }
    ElseIf ($PSCmdlet.ParameterSetName -eq 'Filter') {
      $QueueIdField = Get-AtwsFieldInfo -Entity 'Ticket' -Connection 'Atws' | Where-Object -FilterScript {$_.Name -eq 'QueueId'}      
      Foreach ($Item in $QueueIdField.PicklistValues) {
        $Result += New-Object -TypeName PSObject -Property @{
          QueueName = $Item.Label
          Id        = $Item.Value
          IsSystem  = $Item.IsSystem
          IsActive  = $Item.IsActive
        }
      }
      # Convert $Fitler to a Where-Object compatible filterscript
      $Filter = $Filter -replace '\b(\w+\s+\-[^aAoO])', '$$_.$1'
      $FilterScript = [ScriptBlock]::Create($Filter) 
      $Result = $Result | Where-Object -FilterScript $FilterScript
    }
    Else {
      $Result = New-Object Autotask.EntityInfo
      $Result.CanQuery = $true
      $Result.Name = $Entity
    }


    Write-Verbose -Message ('{0}: Number of entities returned by base query: {1}' -F $MyInvocation.MyCommand.Name, $Result.Count)

  }


  End {
    Write-Verbose -Message ('{0}: End of function' -F $MyInvocation.MyCommand.Name)
    If ($Result) {Return $Result}
  }
}
