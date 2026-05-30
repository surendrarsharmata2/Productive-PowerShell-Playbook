$translationIntegrationPoints = @(
 [Spe.Core.Modules.IntegrationPoints]::ContentEditorContextMenuFeature,
 [Spe.Core.Modules.IntegrationPoints]::ContentEditorContextualRibbonFeature,
 [Spe.Core.Modules.IntegrationPoints]::ContentEditorInsertItemFeature,
 [Spe.Core.Modules.IntegrationPoints]::ContentEditorRibbonFeature,
 [Spe.Core.Modules.IntegrationPoints]::ControlPanelFeature,
 [Spe.Core.Modules.IntegrationPoints]::IsePluginFeature,
 [Spe.Core.Modules.IntegrationPoints]::ReportActionFeature,
 [Spe.Core.Modules.IntegrationPoints]::ReportExportFeature,
 [Spe.Core.Modules.IntegrationPoints]::ReportStartMenuFeature,
 [Spe.Core.Modules.IntegrationPoints]::ToolboxFeature,
 [Spe.Core.Modules.IntegrationPoints]::TasksFeature
)

$featureRoots = $translationIntegrationPoints | ForEach-Object { Get-SpeModuleFeatureRoot -Feature $_ }
foreach($featureRoot in $featureRoots) {
    Write-Host "Processing root $($featureRoot.ItemPath)"
    $items = Get-ChildItem -Path "master:" -ID $featureRoot.ID -Recurse
    foreach($item in $items) {
        if([string]::IsNullOrEmpty($item."__Display name")) {
            Write-Host "- Updating display name for $($item.ItemPath)"
            $item."__Display name" = $item.Name
        }
    }
}

