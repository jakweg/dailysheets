import { google } from 'googleapis'
import express from 'express'
import * as fs from 'fs/promises'

const DATA_START_COLUMN = 'E'
const RESULT_DESCRIPTION_COLUMN = 'A'
const START_DATE_COLUMN = 'D1'

const spreadsheetId = process.env.SHEET_ID;

const keys = JSON.parse(await fs.readFile('./account.key.json', {encoding: 'utf-8'}))
const scopes = ["https://www.googleapis.com/auth/spreadsheets"]

const client = new google.auth.JWT(
    keys.client_email,
    null,
    keys.private_key,
    scopes
);

client.authorize((error, tokens) => {
    if (error) {
        console.log(error);
        process.exit(1)
    } else {
        console.log("Connected to google sheets!");
    }
});

async function getRecords(range) {
    const googleSheetApi = google.sheets({ version: 'v4', auth: client });
    const readOptions = {
        spreadsheetId,
        range: 'Główny!' + range,
        // dateTimeRenderOption: 'SERIAL_NUMBER',
        // valueRenderOption: 'UNFORMATTED_VALUE',
    };

    const dataFromSheet = await googleSheetApi.spreadsheets.values.get({...readOptions,});
    const allRecords = dataFromSheet.data.values;
    return allRecords
}

async function setRecords(range, values) {
    const googleSheetApi = google.sheets({ version: 'v4', auth: client });
    const result = await googleSheetApi.spreadsheets.values.update({
        spreadsheetId,
        range: 'Główny!' + range,
        valueInputOption: 'USER_ENTERED', // RAW
        resource: {
            "majorDimension": "COLUMNS",
            values,
        },
    })

    return result
}

const app = express()
app.use(express.json());
app.use((req, res, next) => {
    const token = req.header('authorization')?.split?.(' ')?.[1]
    if (token !== process.env.TOKEN || !process.env.TOKEN) return res.sendStatus(401)
    next()
})
app.listen(+process.env.PORT || 3000)

app.get('/dates', async (req, res) => {
    res.setHeader('Content-Type', 'application/json')
    const dates = (await getRecords(`${DATA_START_COLUMN}1:1`))[0]
    const startDateRecord = (await getRecords(`${START_DATE_COLUMN}:${START_DATE_COLUMN}`))[0][0];
    const [year, month, day] = startDateRecord
      .split("-")
      .map((e) => parseInt(e, 10));
    const startDate = new Date(year, month - 1, day);
    const nowDate = new Date();
    const suggestedToday = (nowDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000) | 0

    res.end(JSON.stringify({dates, suggestedToday}))
})

app.get('/goals', async (req, res) => {
    res.setHeader('Content-Type', 'application/json')

    const raw = await getRecords('B2:C')

    const categories = [];
    const mapped = raw.map(([category, goalName]) => {
        if (category) {
            categories.push(category)
        }
        return [categories.length - 1, goalName]
    })

    res.end(JSON.stringify({
        categories, goals: mapped,
    }))
})

app.post('/push', async (req, res) => {
    const body = req.body
    if (!body) return res.sendStatus(400)
    
    /** @type {string[]} */
    const goals = body.goals
    /** @type {number[]} */
    const results = body.results
    /** @type {string} */
    const date = body.date

    console.log('submitting', { date, goals, results, })
    
    const datesRaw = (await getRecords(`${DATA_START_COLUMN}1:1`))[0]
    const dateIndex = datesRaw.indexOf(date)
    if (dateIndex < 0) return res.sendStatus(400)
    
    const goalsRaw = (await getRecords(`C2:C`)).map(e => e[0])

    const outputArrayWithTextResults = new Array(goalsRaw.length).fill(null);
    for (const [index, result] of Object.entries(results)) {
        const goal = goals[index];
        const goalInRawIndex = goalsRaw.indexOf(goal)
        if (goalInRawIndex >= 0) {
            if (result >= 0 && result <= 6) {
                outputArrayWithTextResults[goalInRawIndex] = `=${RESULT_DESCRIPTION_COLUMN}${result + 2}`
            }
        }
    }

    
    const offsetArray = new Array(dateIndex).fill([])
    await setRecords(`${DATA_START_COLUMN}2:ZZZ999`, [...offsetArray, outputArrayWithTextResults])

    res.setHeader('Content-Type', 'application/json').end(JSON.stringify({}))
})