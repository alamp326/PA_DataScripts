# -*- coding: utf-8 -*-
"""
This code gets hisotrical PurpleAir data from new PurpleAir API for a group of monitors and stores them in a file structure in my documents.

Data from the site are in bytes/text and NOT in JSON format.

Created on Fri Jun 10 21:34:01 2022

@author: Zuber Farooqui, Ph.D.

Modified Wed Feb 15 17:00:00 2023

@author: Aaron Lamplugh, Ph.D.
"""

import requests
import pandas as pd
from datetime import datetime
import time
import json
import os
from os.path import join, getsize
from pathlib import Path
import glob
from io import StringIO

# API Keys provided by PurpleAir(c)
key_read  = 'Enter Read Key Here'

# Sleep Seconds
sleep_seconds = 3 # wait sleep_seconds after each query

# Data download period. Enter Start and end Dates
bdate = '03-18-2022'
edate = '03-24-2022'

#Sensor List for Data Download
groupid = 'Enter 4-digit group number here'

# Average_time. The desired average in minutes, one of the following: 0 (real-time), 
# 10 (default if not specified), 30, 60, 360 (6 hour), 1440 (1 day)
average_time=0 # or 10  or 0 (Current script is set only for real-time, 10, or 60 minutes data)


def get_sensorslist(groupid,key_read):
    # PurpleAir API URL
    root_url = 'https://api.purpleair.com/v1/groups/'

    fields_list = ['id','sensor_index','created'] 
            
    # Final API URL
    api_url = root_url + groupid + f'?api_key={key_read}'
    print(api_url)
    
    # Getting data
    response = requests.get(api_url)

    if response.status_code == 200:
        #print(response.text)
        json_data = json.loads(response.content)['members']
        df = pd.DataFrame.from_records(json_data)
        df.columns = fields_list
    else:
        raise requests.exceptions.RequestException
    
    # writing to csv file - Enter Directory info here
    folderpath = r'C:\Users\user\Documents\python_stuff\sensors_list'
    filename = folderpath + '\sensors_list.csv'
    df.to_csv(filename, index=False, header=True)
            
    # Creating a Sensors 
    sensorslist = list(df.id)
    print(sensorslist)
    return sensorslist

def get_historicaldata(sensors_list,bdate,edate,average_time,key_read):
    
    # Historical API URL
    root_api_url = 'https://api.purpleair.com/v1/groups/' + groupid + '/members/'
    
    # Average time: The desired average in minutes, one of the following:0 (real-time),10 (default if not specified),30,60
    average_api = f'&average={average_time}'

    # Creating fields api url from fields list to download the data: Note: Sensor ID/Index will not be downloaded as default
    # Secondary data file fields (A)
    fields_list_sec_a = ['0.3_um_count_a', '0.5_um_count_a', '1.0_um_count_a', '2.5_um_count_a', '5.0_um_count_a', '10.0_um_count_a', 
               'pm1.0_atm_a', 'pm10.0_atm_a']
    for i,f in enumerate(fields_list_sec_a):
        if (i == 0):
            fields_api_url_seca = f'&fields={f}'
        else:
            fields_api_url_seca += f'%2C{f}'

    # Secondary data file fields (B)
    fields_list_sec_b = ['0.3_um_count_b', '0.5_um_count_b', '1.0_um_count_b', '2.5_um_count_b', '5.0_um_count_b', '10.0_um_count_b', 
               'pm1.0_atm_b', 'pm10.0_atm_b']
    for i,f in enumerate(fields_list_sec_b):
        if (i == 0):
            fields_api_url_secb = f'&fields={f}'
        else:
            fields_api_url_secb += f'%2C{f}'

    # Primary data file fields (A)
    fields_list_pri_a = ['pm1.0_cf_1_a', 'pm2.5_cf_1_a', 'pm10.0_cf_1_a', 'uptime', 'rssi', 'temperature_a', 
               'humidity_a','pm2.5_atm_a']
    for i,f in enumerate(fields_list_pri_a):
        if (i == 0):
            fields_api_url_pria = f'&fields={f}'
        else:
            fields_api_url_pria += f'%2C{f}'

    # Primary data file fields (B)
    fields_list_pri_b = ['pm1.0_cf_1_b', 'pm2.5_cf_1_b', 'pm10.0_cf_1_b', 'uptime', 'analog_input', 'pressure', 
               'voc','pm2.5_atm_b']
    for i,f in enumerate(fields_list_pri_b):
        if (i == 0):
            fields_api_url_prib = f'&fields={f}'
        else:
            fields_api_url_prib += f'%2C{f}'

    # SD Data Fields
    fields_list_sd = ['firmware_version	', 'hardware', 'temperature_a', 'humidity_a', 'pressure_b', 'analog_input', 'memory', 'rssi', 'uptime', 'pm1.0_cf_1_a', 'pm2.5_cf_1_a', 'pm10.0_cf_1_a', 'pm1.0_atm_a', 'pm2.5_atm_a', 'pm10.0_atm_a',
                '0.3_um_count_a', '0.5_um_count_a','1.0_um_count_a','2.5_um_count_a','5.0_um_count_a','10.0_um_count_a','pm1.0_cf_1_b', 'pm2.5_cf_1_b', 'pm10.0_cf_1_b', 'pm1.0_atm_b', 'pm2.5_atm_b', 'pm10.0_atm_b',
                '0.3_um_count_b', '0.5_um_count_b','1.0_um_count_b','2.5_um_count_b','5.0_um_count_b','10.0_um_count_b']
    for i,f in enumerate(fields_list_sd):
        if (i == 0):
            fields_api_url_sd = f'&fields={f}'
        else:
            fields_api_url_sd += f'%2C{f}'          

    # Dates of Historical Data period
    begindate = datetime.strptime(bdate, '%m-%d-%Y')
    enddate   = datetime.strptime(edate, '%m-%d-%Y')
    
    # Download days based on average
    if (average_time == 60):
        date_list = pd.date_range(begindate,enddate,freq='14d') # for 14 days of data
    else:
        date_list = pd.date_range(begindate,enddate,freq='2d') # for 2 days of data
        
    # Converting to UNIX timestamp
    date_list_unix=[]
    for dt in date_list:
        date_list_unix.append(int(time.mktime(dt.timetuple())))

    # Reversing to get data from end date to start date
    date_list_unix.reverse()
    len_datelist = len(date_list_unix) - 1

    folderlist = list()
        
    # Gets Sensor Data
    for s in sensors_list:

        # Adding sensor_index & API Key
        hist_api_url = root_api_url + f'{s}/history/csv?api_key={key_read}'
        print(hist_api_url)

        # Special URL to grab sensor registration name
        name_api_url = root_api_url + f'{s}?fields=name&api_key={key_read}'

        #get sensor registration name:
        try:
            response = requests.get(name_api_url)
        except:
            print(name_api_url)

        try:
            assert response.status_code == requests.codes.ok
               
            namedf = pd.read_csv(StringIO(response.text), sep=",|:", header=None, skiprows=8, index_col=None, engine='python')

        except AssertionError:
            namedf = pd.DataFrame()
            print('Bad URL!')

        #Response will be the registered name of the sensor            
        sensorname = str(namedf[1][0])
        sensorname = sensorname.strip()
        sensorname = sensorname.strip('\"')
        
        # Creating start and end date api url
        for i,d in enumerate(date_list_unix):
            # Wait time 
            time.sleep(sleep_seconds)
            
            if (i < len_datelist):
                print('Downloading for PA: %s for Dates: %s and %s.' 
                      %(s,datetime.fromtimestamp(date_list_unix[i+1]),datetime.fromtimestamp(d)))
                dates_api_url = f'&start_timestamp={date_list_unix[i+1]}&end_timestamp={d}'

                # Creates final URLs that download data in the format of previous PA downloads and SD card data
                api_url_a = hist_api_url + dates_api_url + average_api + fields_api_url_seca
                api_url_b = hist_api_url + dates_api_url + average_api + fields_api_url_secb
                api_url_c = hist_api_url + dates_api_url + average_api + fields_api_url_pria
                api_url_d = hist_api_url + dates_api_url + average_api + fields_api_url_prib
                api_url_e = hist_api_url + dates_api_url + average_api + fields_api_url_sd

                #creates list of all URLs
                URL_List = [api_url_a,api_url_b,api_url_c,api_url_d,api_url_e]

                for x in URL_List:
                    #queries URLs for data
                    try:
                        response = requests.get(x)
                    except:
                        print(x)
                    #
                    try:
                        assert response.status_code == requests.codes.ok
                
                        # Creating a Pandas DataFrame
                        df = pd.read_csv(StringIO(response.text), sep=",", header=0)
                
                    except AssertionError:
                        df = pd.DataFrame()
                        print('Bad URL!')
            
                    if df.empty:
                        print('------------- No Data Available -------------')
                    else:
                        # Adding Sensor Index/ID
                        df['id'] = s
                
                        #
                        date_time_utc=[]
                        for index, row in df.iterrows():
                            date_time_utc.append(datetime.utcfromtimestamp(row['time_stamp']))
                        df['date_time_utc'] = date_time_utc
                
                        # Dropping duplicate rows
                        df = df.drop_duplicates(subset=None, keep='first', inplace=False)
                        df = df.sort_values(by=['time_stamp'],ascending=True,ignore_index=True)
                    
                        # Writing to Postgres Table (Optional)
                        # df.to_sql('tablename', con=engine, if_exists='append', index=False)
                    
                        # writing to csv file
                        folderpath1 = r'C:\Users\user\Documents\Wildfire Schools Project\PA Data'
                        folderpathdir = folderpath1 + '\\' + bdate + '_to_' + edate
                        if not os.path.exists(folderpathdir):
                            os.makedirs(folderpathdir)

                        folderpath = folderpathdir + '\\' + sensorname
                        if not os.path.exists(folderpath):
                            os.makedirs(folderpath)
                            
                        if x in api_url_b:

                            evenmorespecificpath = folderpath + '\Secondary_B'
                            if not os.path.exists(evenmorespecificpath):
                                os.makedirs(evenmorespecificpath)
                            filename = evenmorespecificpath + '\%s_%s_%s_b.csv' % (sensorname,datetime.fromtimestamp(date_list_unix[i+1]).strftime('%m-%d-%Y'),datetime.fromtimestamp(d).strftime('%m-%d-%Y'))
                            df.to_csv(filename, index=False, header=True)

                            folderlist.append(evenmorespecificpath)

                        elif x in api_url_a:
                            
                            evenmorespecificpath = folderpath + '\Secondary_A'
                            if not os.path.exists(evenmorespecificpath):
                                os.makedirs(evenmorespecificpath)
                            filename = evenmorespecificpath + '\%s_%s_%s.csv' % (sensorname,datetime.fromtimestamp(date_list_unix[i+1]).strftime('%m-%d-%Y'),datetime.fromtimestamp(d).strftime('%m-%d-%Y'))
                            df.to_csv(filename, index=False, header=True)

                            folderlist.append(evenmorespecificpath)

                        elif x in api_url_c:
                            
                            evenmorespecificpath = folderpath + '\Primary_A'
                            if not os.path.exists(evenmorespecificpath):
                                os.makedirs(evenmorespecificpath)
                            filename = evenmorespecificpath + '\%s_%s_%s.csv' % (sensorname,datetime.fromtimestamp(date_list_unix[i+1]).strftime('%m-%d-%Y'),datetime.fromtimestamp(d).strftime('%m-%d-%Y'))
                            df.to_csv(filename, index=False, header=True)

                            folderlist.append(evenmorespecificpath)

                        elif x in api_url_d:

                            evenmorespecificpath = folderpath + '\Primary_B'
                            if not os.path.exists(evenmorespecificpath):
                                os.makedirs(evenmorespecificpath)
                            filename = evenmorespecificpath + '\%s_%s_%s_b.csv' % (sensorname,datetime.fromtimestamp(date_list_unix[i+1]).strftime('%m-%d-%Y'),datetime.fromtimestamp(d).strftime('%m-%d-%Y'))
                            df.to_csv(filename, index=False, header=True)

                            folderlist.append(evenmorespecificpath)

                        else:

                            evenmorespecificpath = folderpath + '\SD_Format'
                            if not os.path.exists(evenmorespecificpath):
                                os.makedirs(evenmorespecificpath)
                            filename = evenmorespecificpath + '\%s_%s_%s.csv' % (sensorname,datetime.fromtimestamp(date_list_unix[i+1]).strftime('%m-%d-%Y'),datetime.fromtimestamp(d).strftime('%m-%d-%Y'))
                            df.to_csv(filename, index=False, header=True)

                            folderlist.append(evenmorespecificpath)

    return folderlist

                            
def combine_files(folderlist):

    # Combines csv files in sensor folders into a combined file
    for s in folderlist:

        os.chdir(s)
        extension = 'csv'
        
        all_filenames = [i for i in glob.glob('*.csv')]

        combined_csv = pd.concat([pd.read_csv(f) for f in all_filenames ])
        combined_csv.to_csv( "combined_files.csv", index=False, encoding='utf-8-sig')

        if "Secondary_A" in s:

            x=Path(s)
            
            lessspecificDir = str(x.parent)
            y=Path(lessspecificDir)
           
            evenlessspecific = str(y.parent)
            z=Path(evenlessspecific)

            filename = str(y.name)+".csv"
            filepath = Path(filename)
            if filepath.is_file():
                os.remove(filepath)

            newname = evenlessspecific + "\WeeklyCheck"
            
            if not os.path.exists(newname):
                os.makedirs(newname)

            os.chdir(newname)

            combined_csv.to_csv(filename, index=False, encoding='utf-8-sig')
        

        elif "Secondary_B" in s:

            x=Path(s)

            lessspecificDir = str(x.parent)
            y=Path(lessspecificDir)
            
            evenlessspecific = str(y.parent)
            z=Path(evenlessspecific)

            filename = str(y.name) + " B.csv"
            filepath = Path(filename)
            if filepath.is_file():
                os.remove(filepath)            

            newname = evenlessspecific + "\WeeklyCheck"
            
            if not os.path.exists(newname):
                os.makedirs(newname)

            os.chdir(newname)

            combined_csv.to_csv(filename, index=False, encoding='utf-8-sig') 

# Getting PA data
sensors_list = get_sensorslist(groupid,key_read)
folderlist = get_historicaldata(sensors_list,bdate,edate,average_time,key_read)
combine_files(folderlist)
