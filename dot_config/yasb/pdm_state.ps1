try {
    # 发送请求并自动解析 JSON
    $Response = Invoke-RestMethod -Uri "http://127.0.0.1:8848/nacos/v1/ns/instance/list?serviceName=pisx-pdm" -ErrorAction Stop
    $Result = $Response.hosts[0].healthy
    # 开始判断状态
    if ($null -eq $Result) {
        Write-Output 'pisx-pdm: <span style="color: #6c7086;">󰝥</span>'
    } elseif ($Result -eq $true) {
        Write-Output 'pisx-pdm: <span style="color: #a6e3a1;">󰝥</span>'
    } elseif ($Result -eq $false) {
        Write-Output 'pisx-pdm: <span style="color: #f38ba8;">󰝥</span>'
    }
} catch {
    # 捕获网络请求失败、404 或端口不通等异常
    Write-Output 'pisx-pdm: <span style="color: #f38ba8;">󰝥</span>'
}
