$projectId = "migo-app-3030e"
$baseUrl = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/areas"

# Areas data: Zone Slugs and their areas
$areasData = @{
    "dubai" = @(
        @{id="downtown-dubai"; name="Downtown Dubai"; order=1},
        @{id="dubai-marina"; name="Dubai Marina"; order=2},
        @{id="jumeirah"; name="Jumeirah"; order=3},
        @{id="deira"; name="Deira"; order=4}
    )
    "abu-dhabi" = @(
        @{id="corniche"; name="Corniche"; order=1},
        @{id="al-reem-island"; name="Al Reem Island"; order=2}
    )
    "sharjah" = @(
        @{id="al-majaz"; name="Al Majaz"; order=1},
        @{id="al-nahda"; name="Al Nahda"; order=2}
    )
    "riyadh" = @(
        @{id="olaya"; name="Olaya"; order=1},
        @{id="al-malaz"; name="Al Malaz"; order=2}
    )
    "jeddah" = @(
        @{id="al-balad"; name="Al Balad"; order=1},
        @{id="corniche-jeddah"; name="Corniche"; order=2}
    )
    "dammam" = @(
        @{id="al-faisaliyah"; name="Al Faisaliyah"; order=1}
    )
    "kuwait-city" = @(
        @{id="salmiya"; name="Salmiya"; order=1},
        @{id="fahaheel"; name="Fahaheel"; order=2}
    )
    "hawalli" = @(
        @{id="salwa"; name="Salwa"; order=1}
    )
    "muscat" = @(
        @{id="al-qurum"; name="Al Qurum"; order=1},
        @{id="ruwi"; name="Ruwi"; order=2}
    )
    "salalah" = @(
        @{id="salalah-center"; name="Salalah Center"; order=1}
    )
    "manama" = @(
        @{id="seef"; name="Seef"; order=1},
        @{id="juffair"; name="Juffair"; order=2}
    )
    "muharraq" = @(
        @{id="arad"; name="Arad"; order=1}
    )
    "kerala" = @(
        @{id="kochi"; name="Kochi"; order=1},
        @{id="trivandrum"; name="Trivandrum"; order=2},
        @{id="kozhikode"; name="Kozhikode"; order=3},
        @{id="thrissur"; name="Thrissur"; order=4}
    )
    "mumbai" = @(
        @{id="andheri"; name="Andheri"; order=1},
        @{id="bandra"; name="Bandra"; order=2},
        @{id="colaba"; name="Colaba"; order=3}
    )
    "delhi" = @(
        @{id="connaught-place"; name="Connaught Place"; order=1},
        @{id="karol-bagh"; name="Karol Bagh"; order=2}
    )
    "bangalore" = @(
        @{id="indiranagar"; name="Indiranagar"; order=1},
        @{id="koramangala"; name="Koramangala"; order=2}
    )
    "chennai" = @(
        @{id="t-nagar"; name="T Nagar"; order=1},
        @{id="adyar"; name="Adyar"; order=2}
    )
}

foreach ($zoneSlug in $areasData.Keys) {
    $areasList = $areasData[$zoneSlug]
    foreach ($area in $areasList) {
        $docId = $area.id
        $name = $area.name
        $order = $area.order
        $url = "$baseUrl/$docId"

        $body = @{
            fields = @{
                name = @{ stringValue = $name }
                zoneSlug = @{ stringValue = $zoneSlug }
                order = @{ integerValue = "$order" }
                active = @{ booleanValue = $true }
            }
        } | ConvertTo-Json -Depth 5

        try {
            $response = Invoke-RestMethod -Uri $url -Method Patch -Body $body -ContentType "application/json"
            Write-Host "✅ Added: $name ($zoneSlug)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed: $name ($zoneSlug) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n🎉 All areas added!" -ForegroundColor Cyan