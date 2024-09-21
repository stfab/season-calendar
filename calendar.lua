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
function parse_date_time(date, time)
    local date_year = string.format("%04d", tonumber(date:match("[^\p]+%p[^\p]+%p([^\p]+)")))
    local date_month = string.format("%02d", tonumber(date:match("[^\p]+%p([^\p]+)%p[^\p]+")))
    local date_day = string.format("%02d", tonumber(date:match("([^\p]+)%p[^\p]+%p[^\p]+")))
    local time_hour = string.format("%02d", tonumber(time:match("(%d+)%p%d+")))
    local time_minute = string.format("%02d", tonumber(time:match("%d+%p(%d+)")))

    return {
        year = date_year,
        month = date_month,
        day = date_day,
        hour = time_hour,
        minute = time_minute
    }
end

-- function to create ical event
function create_ical_event(matchday, date, time, host, guest)
    local date_time = parse_date_time(date, time)

    -- calculate end time
    local endtime = string.format("%02d", tonumber(date_time.hour) + match_duration) .. date_time.minute

    local event = {
        "BEGIN:VEVENT",
        "UID:" .. os.time() .. "@example.com",
        "DTSTAMP:" .. os.date("!%Y%m%dT%H%M%SZ"),
        "DTSTART:" .. date_time.year .. date_time.month .. date_time.day .. "T" .. date_time.hour .. date_time.minute .. "00",
        "DTEND:" .. date_time.year .. date_time.month .. date_time.day .. "T" .. endtime .. "00",
        "SUMMARY:" .. matchday .. " " .. host .. "- " .. guest,
        "END:VEVENT"
    }
    return table.concat(event, "\n")
end

-- function to parse the schedule
function parse_schedule(schedule, team_name)
    local events = {}
    local matchday = nil
    for line in schedule:gmatch("[^\r\n]+") do
        if line:match("Matchday") then
            matchday = line
        else
            local match_number, date_time, host, guest = line:match("(%d+)%s+([^\t]+)%s+([^\t]+)%s+([^\t]+)")
            if host == team_name or guest == team_name then
                local date, time = date_time:match("[^\s]%s+([^\s]+)%s%p%s([^\s]+)")
                host = convert_umlauts(host)
                guest = convert_umlauts(guest)
                table.insert(events, create_ical_event(matchday, date, time, host, guest))
            end
        end
    end
    return events
end

-- main function
function main()
    local file = io.open(file_name .. ".txt", "r")
    if not file then
        print("Error opening file: " .. file_name .. ".txt")
        return
    end

    local schedule = file:read("*all")
    file:close()

    local events = parse_schedule(schedule, team_name .. " ") -- empty space is necessary

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

    print("Calendar file created: " .. file_name .. ".ics")
end

main()
