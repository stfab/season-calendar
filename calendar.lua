-- [global variables, change for your needs]
-- name of the file with the schedule
local file_name = "spielplan"
-- name of the team to create the calendar for
local team_name = "KC 80 Kurpfalz NS Plankst. 1"
-- duration of a match in hours
local match_duration = 3

-- function to convert umlauts
function convert_umlauts(text)
    text = text:gsub("ä", "ae")
    text = text:gsub("ö", "oe")
    text = text:gsub("ü", "ue")
    text = text:gsub("Ä", "Ae")
    text = text:gsub("Ö", "Oe")
    text = text:gsub("Ü", "Ue")
    text = text:gsub("ß", "ss")
    return text
end

-- function to parse date and time
function parse_date_time(datum, zeit)
    local datum_year = string.format("%04d", tonumber(datum:match("[^\p]+%p[^\p]+%p([^\p]+)")))
    local datum_month = string.format("%02d", tonumber(datum:match("[^\p]+%p([^\p]+)%p[^\p]+")))
    local datum_day = string.format("%02d", tonumber(datum:match("([^\p]+)%p[^\p]+%p[^\p]+")))
    local zeit_hour = string.format("%02d", tonumber(zeit:match("(%d+)%p%d+")))
    local zeit_minute = string.format("%02d", tonumber(zeit:match("%d+%p(%d+)")))

    return {
        year = datum_year,
        month = datum_month,
        day = datum_day,
        hour = zeit_hour,
        minute = zeit_minute
    }
end

-- function to create ical event
function create_ical_event(spieltag, datum, zeit, gastgeber, gast)
    local date_time = parse_date_time(datum, zeit)

    -- calculate end time
    local endtime = string.format("%02d", tonumber(date_time.hour) + match_duration) .. date_time.minute

    local event = {
        "BEGIN:VEVENT",
        "UID:" .. os.time() .. "@example.com",
        "DTSTAMP:" .. os.date("!%Y%m%dT%H%M%SZ"),
        "DTSTART:" .. date_time.year .. date_time.month .. date_time.day .. "T" .. date_time.hour .. date_time.minute .. "00",
        "DTEND:" .. date_time.year .. date_time.month .. date_time.day .. "T" .. endtime .. "00",
        "SUMMARY:" .. spieltag .. " " .. gastgeber .. "- " .. gast,
        "END:VEVENT"
    }
    return table.concat(event, "\n")
end

-- function to parse the schedule
function parse_spielplan(spielplan, team_name)
    local events = {}
    local spieltag = nil
    for line in spielplan:gmatch("[^\r\n]+") do
        if line:match("Spieltag") then
            spieltag = line
        else
            local spielnummer, datum_zeit, gastgeber, gast = line:match("(%d+)%s+([^\t]+)%s+([^\t]+)%s+([^\t]+)")
            if gastgeber == team_name or gast == team_name then
                local datum, zeit = datum_zeit:match("[^\s]%s+([^\s]+)%s%p%s([^\s]+)")
                gastgeber = convert_umlauts(gastgeber)
                gast = convert_umlauts(gast)
                table.insert(events, create_ical_event(spieltag, datum, zeit, gastgeber, gast))
            end
        end
    end
    return events
end

-- main function
function main()
    local file = io.open(file_name .. ".txt", "r")
    if not file then
        print("Fehler beim Öffnen der Datei: " .. file_name .. ".txt")
        return
    end

    local spielplan = file:read("*all")
    file:close()

    local events = parse_spielplan(spielplan, team_name .. " ") -- empty space is necessary

    local ical = {
        "BEGIN:VCALENDAR",
        "X-WR-TIMEZONE:Europe/Berlin",
        "VERSION:2.0",
        "PRODID:-//" .. team_name,
        table.concat(events, "\n"),
        "END:VCALENDAR"
    }

    local ical_file = io.open(file_name .. ".ics", "w")
    ical_file:write(table.concat(ical, "\n"))
    ical_file:close()

    print("Kalenderdatei wurde erstellt: " .. file_name .. ".ics")
end

main()
