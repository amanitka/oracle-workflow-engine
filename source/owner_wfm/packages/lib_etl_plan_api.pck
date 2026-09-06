CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_plan_api is

  ---------------------------------------------------------------------------------------------------------
  -- author:  Workflow Team
  -- created: 05.04.2018
  -- purpose: API for process plan  
  ---------------------------------------------------------------------------------------------------------


  TYPE t_process_plan IS RECORD 
   (
    id_process                 INTEGER,
    name_process               VARCHAR2(100),
    code_process_category      VARCHAR2(50),
    date_effective             DATE,
    flag_plan_status           VARCHAR2(1),
    flag_multiple_start        VARCHAR2(1),
    flag_plan_exist            VARCHAR2(1),
    code_status                VARCHAR2(1)
   );
   
  TYPE tt_process_plan IS TABLE OF t_process_plan INDEX BY BINARY_INTEGER; 

  TYPE tt2_process_plan IS TABLE OF t_process_plan; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: get_process_plan
  -- purpose:        generating plans for running of processes for specific time period
  --
  -- In case you want generate plan for all processes, don't fill p_id_process and p_code_process_group
  --
  -- p_id_process         - ETL_PROCESS.ID_PROCESS - id of process
  --                      - in case you want generate plan for one specific process
  -- p_code_process_group - ETL_PROCESS.CODE_PROCESS_GROUP - code of process group
  --                      - in case you want generate plan for processes in specific group
  -- p_date_period_from/p_date_period_to  - time period
  -- p_force              - enforcement of rewriting of stored plan
  -- p_plans is collection of plans returned this procedure
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_plan(p_id_process          IN INTEGER  DEFAULT NULL, 
                             p_code_process_group  IN VARCHAR2 DEFAULT NULL,                         
                             p_date_period_from    IN DATE     DEFAULT SYSDATE,
                             p_date_period_to      IN DATE     DEFAULT ADD_MONTHS(SYSDATE,1),
                             p_force               IN VARCHAR2 DEFAULT 'N',
                             p_plans               OUT tt_process_plan);

  ---------------------------------------------------------------------------------------------------------
  -- function name: SHOW_PROCESS_PLAN
  -- purpose:       show list of process plans for all processes in interval p_window_start to p_window_end
  ---------------------------------------------------------------------------------------------------------
  FUNCTION show_process_plan(p_window_start             IN DATE DEFAULT trunc(SYSDATE,'MM'),
                             p_window_end               IN DATE DEFAULT add_months(trunc(SYSDATE,'MM'),1)-1,
                             p_code_process_category    IN VARCHAR2 DEFAULT NULL) RETURN tt2_process_plan PIPELINED;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: store_rocess_plans
  -- purpose:        store plans to ETL_PROCESS_PLAN
  --
  -- p_plans is collection of plans
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE store_process_plans(p_plans  IN tt_process_plan);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: store_process_plans
  -- purpose:        store plans to ETL_PROCESS_PLAN via DWH Console
  --
  -- p_id_process          - id of process
  -- p_date_effective_from - date_effective from which will be set the plan
  -- p_date_effective_to   - date effective to which will be set the plan
  -- p_flag_plan_status    - flag of status plan
  -- p_flag_multiple_start - flag multipple start
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE store_process_plans(p_id_process           IN INTEGER,
                                p_date_effective_from  IN DATE,
                                p_date_effective_to    IN DATE,
                                p_flag_plan_status     IN VARCHAR2,
                                p_flag_multiple_start  IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: store_rocess_plan
  -- purpose:        store plan for process for specific date_effective to ETL_PROCESS_PLAN
  --
  -- p_plan is record of plan
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE store_process_plan(p_plan  IN t_process_plan);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: generate_process_plan
  -- purpose:        generate and store plans for running of processes for specific time period
  --
  -- In case you want generate plan for all processes, don't fill p_id_process and p_code_process_group
  --
  -- p_id_process         - ETL_PROCESS.ID_PROCESS - id of process
  --                      - in case you want generate plan for one specific process
  -- p_code_process_group - ETL_PROCESS.CODE_PROCESS_GROUP - code of process group
  --                      - in case you want generate plan for processes in specific group
  -- p_date_period_from/p_date_period_to  - time period
  -- p_force              - enforcement of rewriting of stored plan
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE generate_process_plan(p_id_process          IN INTEGER  DEFAULT NULL, 
                                  p_code_process_group  IN VARCHAR2 DEFAULT NULL,                         
                                  p_date_period_from    IN DATE     DEFAULT SYSDATE,
                                  p_date_period_to      IN DATE     DEFAULT ADD_MONTHS(SYSDATE,1),
                                  p_force               IN VARCHAR2 DEFAULT 'N');
  
  
  PROCEDURE generate_process_planWF(p_process_key    IN NUMBER,
                                    p_effective_date IN DATE,
                                    p_data_type      IN VARCHAR2);

                           
END lib_etl_plan_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_plan_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------   
  c_mod_name              CONSTANT VARCHAR2(30) := 'LIB_ETL_PLAN_API';    
  c_flag_n                CONSTANT VARCHAR2(1)  := 'N';
  c_flag_y                CONSTANT VARCHAR2(1)  := 'Y';
  c_log_type_message      CONSTANT VARCHAR2(10) := 'MESSAGE';
  c_log_type_error        CONSTANT VARCHAR2(10) := 'ERROR';  
  v_text_check_message    VARCHAR2(2000);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: get_process_plan
  -- purpose:        generating plans for running of processes for specific time period
  --
  -- In case you want generate plan for all processes, don't fill p_id_process and p_code_process_group
  --
  -- p_id_process         - ETL_PROCESS.ID_PROCESS - id of process
  --                      - in case you want generate plan for one specific process
  -- p_code_process_group - ETL_PROCESS.CODE_PROCESS_GROUP - code of process group
  --                      - in case you want generate plan for processes in specific group
  -- p_date_period_from/p_date_period_to  - time period
  -- p_force              - enforcement of rewriting of stored plan
  -- p_plans is collection of plans returned this procedure
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_plan(p_id_process          IN INTEGER  DEFAULT NULL, 
                             p_code_process_group  IN VARCHAR2 DEFAULT NULL,                         
                             p_date_period_from    IN DATE     DEFAULT SYSDATE,
                             p_date_period_to      IN DATE     DEFAULT ADD_MONTHS(SYSDATE,1),
                             p_force               IN VARCHAR2 DEFAULT 'N',
                             p_plans               OUT TT_PROCESS_PLAN)
    IS

   j integer := 0;
   CURSOR c_plans is
        with days as (
            --days in month
            select trunc(p_date_period_from)-1+level date_effective
            FROM dual
            CONNECT BY LEVEL <= trunc(p_date_period_to)+1 - trunc(p_date_period_from)
        ),
        processes as (
            --list of processes
            select * 
            FROM owner_wfm.etl_process 
            where flag_deleted = c_flag_n
              and id_process in (
               select id_process from owner_wfm.etl_process where id_process = p_id_process
               union
               select id_process from owner_wfm.etl_process where code_process_group = p_code_process_group
               union
               select id_process from owner_wfm.etl_process where 1=1 and (p_id_process is null and p_code_process_group is null)
              )
        )
        select 
            id_process,
            name_workflow AS name_process,
            code_process_category,
            date_effective,
            case 
              when p_force = c_flag_y then flag_plan_status
              else NVL(flag_plan_status_planned,flag_plan_status)
            end flag_plan_status,
            case 
              when p_force = c_flag_y then     
                             case 
                               when flag_plan_status = c_flag_n then c_flag_n
                               else flag_multiple_start 
                             end
              else NVL(flag_multiple_start_planned,case 
                                                     when flag_plan_status = c_flag_n then c_flag_n
                                                     else flag_multiple_start 
                                                   end)
            end flag_multiple_start,
            DECODE(date_effective_planned,null,c_flag_n,c_flag_y) as flag_plan_exist
        from (
            select
                id_process,
                name_workflow,
                code_process_category,
                --generated plan
                date_effective,
                nvl(
                case
                  --plan for week and month
                  when flag_week_plan = c_flag_y and flag_month_plan = c_flag_y 
                    then
                        case
                          when flag_run_week = flag_run_month then flag_run_month
                          when flag_run_month = '?' then flag_run_week
                          when flag_run_week = '?' then flag_run_month
                          else          
                           -- result of Y, N is supposed to be Y
                           c_flag_y
                        end  
                  --last day of month
                  when flag_month_plan = c_flag_y and flag_run_month <> c_flag_y and is_last_day = c_flag_y 
                    then flag_run_month_day_last 
                  else
                  --plan for month or week depending on settings
                    nvl(flag_run_month,flag_run_week)
                end
                ,'?') as flag_plan_status,
                flag_multiple_start,                                                             
                --planned metadata store in etl_process_plan
                date_effective_planned,                                                          
                flag_plan_status_planned,                                                        --
                flag_multiple_start_planned
            from (
                select 
                    t.id_process,
                    t.code_process_category,
                    t.name_workflow,
                    days.date_effective,
                    p.date_effective         as date_effective_planned,
                    p.flag_plan_status       as flag_plan_status_planned,
                    p.flag_multiple_start    as flag_multiple_start_planned,
                    t.flag_multiple_start,
                    t.flag_month_plan, 
                    t.flag_week_plan, 
                    t.flag_run_month_day_last,
                    case
                      when trim(to_char(days.date_effective,'DAY')) = 'MONDAY'    then tp_weekly.flag_run_week_day_1      --Monday
                      when trim(to_char(days.date_effective,'DAY')) = 'TUESDAY'   then tp_weekly.flag_run_week_day_2      --Tuesday
                      when trim(to_char(days.date_effective,'DAY')) = 'WEDNESDAY' then tp_weekly.flag_run_week_day_3      --Wednesday
                      when trim(to_char(days.date_effective,'DAY')) = 'THURSDAY'  then tp_weekly.flag_run_week_day_4      --Thursday
                      when trim(to_char(days.date_effective,'DAY')) = 'FRIDAY'    then tp_weekly.flag_run_week_day_5      --Friday
                      when trim(to_char(days.date_effective,'DAY')) = 'SATURDAY'  then tp_weekly.flag_run_week_day_6      --Saturday
                      when trim(to_char(days.date_effective,'DAY')) = 'SUNDAY'    then tp_weekly.flag_run_week_day_7      --Sunday
                      else null
                    end as flag_run_week,
                    case
                      when to_number(to_char(days.date_effective,'DD')) = 1  then tp_monthly.flag_run_month_day_1 
                      when to_number(to_char(days.date_effective,'DD')) = 2  then tp_monthly.flag_run_month_day_2
                      when to_number(to_char(days.date_effective,'DD')) = 3  then tp_monthly.flag_run_month_day_3 
                      when to_number(to_char(days.date_effective,'DD')) = 4  then tp_monthly.flag_run_month_day_4 
                      when to_number(to_char(days.date_effective,'DD')) = 5  then tp_monthly.flag_run_month_day_5 
                      when to_number(to_char(days.date_effective,'DD')) = 6  then tp_monthly.flag_run_month_day_6 
                      when to_number(to_char(days.date_effective,'DD')) = 7  then tp_monthly.flag_run_month_day_7 
                      when to_number(to_char(days.date_effective,'DD')) = 8  then tp_monthly.flag_run_month_day_8 
                      when to_number(to_char(days.date_effective,'DD')) = 9  then tp_monthly.flag_run_month_day_9 
                      when to_number(to_char(days.date_effective,'DD')) = 10 then tp_monthly.flag_run_month_day_10 
                      when to_number(to_char(days.date_effective,'DD')) = 11 then tp_monthly.flag_run_month_day_11
                      when to_number(to_char(days.date_effective,'DD')) = 12 then tp_monthly.flag_run_month_day_12 
                      when to_number(to_char(days.date_effective,'DD')) = 13 then tp_monthly.flag_run_month_day_13 
                      when to_number(to_char(days.date_effective,'DD')) = 14 then tp_monthly.flag_run_month_day_14 
                      when to_number(to_char(days.date_effective,'DD')) = 15 then tp_monthly.flag_run_month_day_15 
                      when to_number(to_char(days.date_effective,'DD')) = 16 then tp_monthly.flag_run_month_day_16 
                      when to_number(to_char(days.date_effective,'DD')) = 17 then tp_monthly.flag_run_month_day_17 
                      when to_number(to_char(days.date_effective,'DD')) = 18 then tp_monthly.flag_run_month_day_18 
                      when to_number(to_char(days.date_effective,'DD')) = 19 then tp_monthly.flag_run_month_day_19 
                      when to_number(to_char(days.date_effective,'DD')) = 20 then tp_monthly.flag_run_month_day_20 
                      when to_number(to_char(days.date_effective,'DD')) = 21 then tp_monthly.flag_run_month_day_21 
                      when to_number(to_char(days.date_effective,'DD')) = 22 then tp_monthly.flag_run_month_day_22 
                      when to_number(to_char(days.date_effective,'DD')) = 23 then tp_monthly.flag_run_month_day_23 
                      when to_number(to_char(days.date_effective,'DD')) = 24 then tp_monthly.flag_run_month_day_24 
                      when to_number(to_char(days.date_effective,'DD')) = 25 then tp_monthly.flag_run_month_day_25 
                      when to_number(to_char(days.date_effective,'DD')) = 26 then tp_monthly.flag_run_month_day_26 
                      when to_number(to_char(days.date_effective,'DD')) = 27 then tp_monthly.flag_run_month_day_27 
                      when to_number(to_char(days.date_effective,'DD')) = 28 then tp_monthly.flag_run_month_day_28 
                      when to_number(to_char(days.date_effective,'DD')) = 29 then tp_monthly.flag_run_month_day_29 
                      when to_number(to_char(days.date_effective,'DD')) = 30 then tp_monthly.flag_run_month_day_30 
                      when to_number(to_char(days.date_effective,'DD')) = 31 then tp_monthly.flag_run_month_day_31 
                      else null
                    end as flag_run_month,
                    case 
                      when to_char(days.date_effective,'DD') = to_char(last_day(days.date_effective),'DD') then c_flag_y 
                      else c_flag_n 
                    end as is_last_day
                from processes t
                join days on 1=1
                left join owner_wfm.etl_process_plan p 
                  on p.date_effective = days.date_effective
                 and p.id_process = t.id_process
                left join processes tp_monthly 
                  on tp_monthly.id_process = t.id_process 
                 and tp_monthly.flag_month_plan = c_flag_y
                left join processes tp_weekly 
                  on tp_weekly.id_process = t.id_process 
                 and tp_weekly.flag_week_plan = c_flag_y
            )
            order by id_process, date_effective
        );
        
   a_plans tt_process_plan;

  BEGIN

    -- Reset plans info
    a_plans.delete();

    j := 0;
    -- Loop through plans
    FOR i IN c_plans
    LOOP
      
      if p_force = c_flag_n and i.flag_plan_exist = c_flag_y then
         --plan exists, exclude record
         null;
      else 
          j := j+1;
          -- Set plan detail
          a_plans(j).id_process                 := i.id_process;
          a_plans(j).name_process               := i.name_process;
          a_plans(j).code_process_category      := i.code_process_category;
          a_plans(j).date_effective             := i.date_effective;
          a_plans(j).flag_plan_status           := i.flag_plan_status;
          a_plans(j).flag_multiple_start        := i.flag_multiple_start;
          a_plans(j).flag_plan_exist            := i.flag_plan_exist;
      end if;
            
    END LOOP;
    
    -- Set result
    p_plans := a_plans;

  END get_process_plan;

  ---------------------------------------------------------------------------------------------------------
  -- function name: SHOW_PROCESS_PLAN
  -- purpose:       show list of process plans for all processes in interval p_window_start to p_window_end
  ---------------------------------------------------------------------------------------------------------
  FUNCTION show_process_plan(p_window_start             IN DATE DEFAULT trunc(SYSDATE,'MM'),
                             p_window_end               IN DATE DEFAULT add_months(trunc(SYSDATE,'MM'),1)-1, 
                             p_code_process_category    IN VARCHAR2 DEFAULT NULL) RETURN tt2_process_plan PIPELINED
  IS

    c_process_plan   t_process_plan;
    a_process_plan   t_process_plan;

    c_plans          SYS_REFCURSOR;
    v_string         VARCHAR2(32000);    
    v_string_cond    VARCHAR2(100);
    v_window_start   VARCHAR2(100) := to_char(p_window_start,'DD.MM.YYYY');
    v_window_end     VARCHAR2(100) := to_char(p_window_end,'DD.MM.YYYY');
                                
  BEGIN

    IF p_code_process_category IS NULL THEN v_string_cond:=NULL;
    ELSE v_string_cond:= 'AND p.code_process_category = '''||p_code_process_category||'''';
    END IF;

    v_string :='WITH 
       process AS (
              SELECT 
                  p.id_process,
                  p.name_process,
                  p.code_process_category
              FROM owner_wfm.etl_process p 
             WHERE p.flag_deleted <> ''Y''
               '||v_string_cond||'       
       ),      
       base AS (
              SELECT 
                  p.id_process,
                  p.name_process,
                  p.code_process_category,
                  base.date_effective
                FROM (
                    SELECT 
                        TRUNC(to_date('''||v_window_start||''',''DD.MM.YYYY'') - 1 + ROWNUM) AS date_effective
                      FROM DUAL 
                    CONNECT BY ROWNUM <= to_date('''||v_window_end||''',''DD.MM.YYYY'') - to_date('''||v_window_start||''',''DD.MM.YYYY'') + 1
                ) base
                CROSS JOIN process p 
                WHERE 1 = 1
        ),
        p_instance AS (
            SELECT i.id_process, 
                   i.date_effective,
                   NVL(i.code_status, s.code_status) AS code_status,
                   row_number() OVER (PARTITION BY i.id_process, i.date_effective ORDER BY i.dtime_inserted DESC) AS rnb
              FROM owner_wfm.etl_process_instance i  
              JOIN process p ON p.id_process = i.id_process
              LEFT JOIN owner_wfm.etl_process_status s ON s.id_process = i.id_process 
                                                      AND s.date_effective = i.date_effective  
             WHERE i.date_effective BETWEEN to_date('''||v_window_start||''',''DD.MM.YYYY'') AND to_date('''||v_window_end||''',''DD.MM.YYYY'')
        )
        SELECT /*+ RESULT_CACHE parallel(4)*/
           base.id_process,
           base.name_process,
           base.code_process_category,
           base.date_effective,
           NVL(pl.flag_plan_status,''N'') AS flag_plan_status,
           NVL(pl.flag_multiple_start,''N'') AS flag_multiple_start,
           DECODE(pl.flag_plan_status, NULL, ''N'', ''Y'') AS flag_plan_exist,
           CASE
             WHEN pi.code_status = ''COMPLETE'' THEN ''C''
             WHEN pi.code_status = ''RUNNING''  THEN ''R''
             WHEN pi.code_status = ''ERROR''    THEN ''E''
             WHEN pi.code_status = ''CANCEL''   THEN ''X''
             WHEN pi.code_status = ''SUSPEND''  THEN ''S''
             ELSE NULL
           END AS code_status
          FROM base          
          LEFT JOIN owner_wfm.etl_process_plan pl 
            ON pl.id_process = base.id_process
           AND pl.date_effective = base.date_effective
          LEFT JOIN p_instance pi 
            ON base.id_process = pi.id_process
           AND base.date_effective = pi.date_effective 
           AND pi.rnb = 1
        ORDER BY base.id_process, base.date_effective';    

    -- Reset process plan
    a_process_plan := NULL;
    c_process_plan := NULL;

    -- Loop through processes and set array
    OPEN c_plans FOR v_string;
    LOOP
        FETCH c_plans INTO c_process_plan;
        EXIT WHEN c_plans%NOTFOUND;

      -- Set process plan info
      a_process_plan.id_process            := c_process_plan.id_process;
      a_process_plan.name_process          := c_process_plan.name_process;
      a_process_plan.code_process_category := c_process_plan.code_process_category;
      a_process_plan.date_effective        := c_process_plan.date_effective;
      a_process_plan.flag_plan_status      := c_process_plan.flag_plan_status;
      a_process_plan.flag_multiple_start   := c_process_plan.flag_multiple_start;
      a_process_plan.flag_plan_exist       := c_process_plan.flag_plan_exist;
      a_process_plan.code_status           := c_process_plan.code_status;
      PIPE ROW(a_process_plan);    

    END LOOP;
    CLOSE c_plans;
    
    -- Return result
    RETURN;
  
  END show_process_plan;      
                         
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: store_process_plans
  -- purpose:        store plans to ETL_PROCESS_PLAN
  --
  -- p_plans is collection of plans
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE store_process_plans(p_plans  IN tt_process_plan)
    IS

    v_proc_name VARCHAR2(32) := 'storeProcessPlans';
    v_msg       VARCHAR2(1000);
    
  BEGIN
  
    FOR i IN p_plans.FIRST .. p_plans.LAST 
    LOOP        
        store_process_plan(p_plans(i));      
    END LOOP;

    v_text_check_message := 'Plan was stored into ETL_PROCESS_PLAN';
    owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                           p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                           p_text_message       => v_text_check_message);

  EXCEPTION
    WHEN OTHERS THEN
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
  END store_process_plans;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: store_rocess_plans
  -- purpose:        store plans to ETL_PROCESS_PLAN via DWH Console
  --
  -- p_id_process          - id of process
  -- p_date_effective_from - date_effective from which will be set the plan
  -- p_date_effective_to   - date effective to which will be set the plan
  -- p_flag_plan_status    - flag of status plan
  -- p_flag_multiple_start - flag multipple start
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE store_process_plans(p_id_process           IN INTEGER,
                                p_date_effective_from  IN DATE,
                                p_date_effective_to    IN DATE,
                                p_flag_plan_status     IN VARCHAR2,
                                p_flag_multiple_start  IN VARCHAR2)
    IS

    v_proc_name       VARCHAR2(32) := 'storeProcessPlans(DWH Console)';
    v_msg             VARCHAR2(1000);
    v_date_effective  DATE := NULL;
    v_flag_plan_exist VARCHAR2(1 CHAR) := NULL;
    v_start_date      NUMBER;
    v_end_date        NUMBER;
    v_cnt_days        INTEGER;

    a_process_plan           t_process_plan;
    aa_process_plan          tt_process_plan;
    
  BEGIN
      
   v_date_effective := p_date_effective_from;
   v_start_date := to_number(to_char(p_date_effective_from, 'DDD'));
   v_end_date   := to_number(to_char(p_date_effective_to, 'DDD'));
   v_cnt_days := v_end_date-v_start_date+1;   

    FOR i IN 1..v_cnt_days
    LOOP        
      a_process_plan.id_process          := p_id_process;
      a_process_plan.date_effective      := v_date_effective;
      a_process_plan.flag_plan_status    := p_flag_plan_status;
      a_process_plan.flag_multiple_start := p_flag_multiple_start;
      a_process_plan.flag_plan_exist     := v_flag_plan_exist;      
      
      v_date_effective := p_date_effective_from + i;

      aa_process_plan(i) := a_process_plan;

    END LOOP;

    store_process_plans(aa_process_plan);      

  END store_process_plans;


  ---------------------------------------------------------------------------------------------------------
  -- procedure name: store_rocess_plan
  -- purpose:        store plan for process for specific date_effective to ETL_PROCESS_PLAN
  --
  -- p_plan is record of plan
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE store_process_plan(p_plan  IN t_process_plan)

    IS

    v_proc_name VARCHAR2(32) := 'storeProcessPlan';
    v_msg       VARCHAR2(1000);
    
  BEGIN
  
       --Check values before saving
       
       --Check FLAG_PLAN_STATUS
       IF p_plan.flag_plan_status not in ('Y','N','?') then

               v_msg := 'ID_PROCESS('||p_plan.id_process||') DATE_EFFECTIVE('||p_plan.date_effective||') - Invalid FLAG_PLAN_STATUS value - '||p_plan.flag_plan_status||' (allowed values: Y,N,?)';
               v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
               -- Log error
               owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                                      p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                                      p_text_message       => v_text_check_message);

               --raise_application_error (-20999,v_msg);
       END IF;
       
       --Check FLAG_MULTIPLE_START
       IF p_plan.flag_multiple_start not in ('Y','N') then
               raise_application_error (-20999,'Invalid FLAG_MULTIPLE_START value (allowed values: Y,N)');

               v_msg := 'ID_PROCESS('||p_plan.id_process||') DATE_EFFECTIVE('||p_plan.date_effective||') - Invalid FLAG_MULTIPLE_START value - '||p_plan.flag_multiple_start||' (allowed values: Y,N)';
               v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
               -- Log error
               owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                                      p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                                      p_text_message       => v_text_check_message);

               --raise_application_error (-20999,v_msg);

       END IF;
    
       IF (p_plan.flag_plan_exist = 'Y') THEN

           --UPDATE
           UPDATE owner_wfm.etl_process_plan t
           SET
             t.flag_plan_status    = p_plan.flag_plan_status,
             t.flag_multiple_start = p_plan.flag_multiple_start,
             t.dtime_updated       = sysdate,
             t.user_updated        = user 
           WHERE t.id_process = p_plan.id_process
             AND t.date_effective = p_plan.date_effective;

       ELSIF (p_plan.flag_plan_exist = 'N') THEN

           --INSERT
           INSERT INTO owner_wfm.etl_process_plan t
            (
                id_process, 
                date_effective, 
                flag_plan_status, 
                flag_multiple_start, 
                dtime_inserted, 
                user_inserted, 
                dtime_updated, 
                user_updated
            )
            VALUES( 
                p_plan.id_process, 
                p_plan.date_effective,
                p_plan.flag_plan_status, 
                p_plan.flag_multiple_start, 
                sysdate,
                user,
                sysdate,
                user 
            );
       ELSE 
       
           MERGE INTO owner_wfm.etl_process_plan t
           USING ( 
             SELECT 
                p_plan.id_process          AS id_process, 
                p_plan.date_effective      AS date_effective,
                p_plan.flag_plan_status    AS flag_plan_status, 
                p_plan.flag_multiple_start AS flag_multiple_start, 
                SYSDATE                    AS dtime_inserted,
                USER                       AS user_inserted,
                SYSDATE                    AS dtime_updated,
                USER                       AS user_updated
             FROM dual
           ) s 
           ON (s.id_process = t.id_process AND s.date_effective = t.date_effective)
           WHEN NOT MATCHED THEN
           INSERT
           (
                id_process, 
                date_effective, 
                flag_plan_status, 
                flag_multiple_start, 
                dtime_inserted, 
                user_inserted, 
                dtime_updated, 
                user_updated
           )
           VALUES(
                s.id_process, 
                s.date_effective, 
                s.flag_plan_status, 
                s.flag_multiple_start, 
                s.dtime_inserted, 
                s.user_inserted, 
                s.dtime_updated, 
                s.user_updated
           )
           WHEN MATCHED THEN
               UPDATE SET t.flag_plan_status    = s.flag_plan_status,
                          t.flag_multiple_start = s.flag_multiple_start,
                          t.dtime_updated       = s.dtime_updated,
                          t.user_updated        = s.user_updated;

       END IF; 
       
    commit;

  END store_process_plan;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: generate_process_plan
  -- purpose:        generate and store plans for running of processes for specific time period
  --
  -- In case you want generate plan for all processes, don't fill p_id_process and p_code_process_group
  --
  -- p_id_process         - ETL_PROCESS.ID_PROCESS - id of process
  --                      - in case you want generate plan for one specific process
  -- p_code_process_group - ETL_PROCESS.CODE_PROCESS_GROUP - code of process group
  --                      - in case you want generate plan for processes in specific group
  -- p_date_period_from/p_date_period_to  - time period
  -- p_force              - enforcement of rewriting of stored plan
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE generate_process_plan(p_id_process          IN INTEGER  DEFAULT NULL, 
                                  p_code_process_group  IN VARCHAR2 DEFAULT NULL,                         
                                  p_date_period_from    IN DATE     DEFAULT SYSDATE,
                                  p_date_period_to      IN DATE     DEFAULT ADD_MONTHS(SYSDATE,1),
                                  p_force               IN VARCHAR2 DEFAULT 'N')
  IS

   a_plans tt_process_plan;

  begin
  
    --get plans for processes
    get_process_plan(p_id_process          => p_id_process, 
                     p_code_process_group  => p_code_process_group,                         
                     p_date_period_from    => p_date_period_from,
                     p_date_period_to      => p_date_period_to,
                     p_force               => p_force,
                     p_plans               => a_plans);
    
    --store get plans
    store_process_plans(p_plans  => a_plans);

  END generate_process_plan;

  PROCEDURE generate_process_planWF(p_process_key    IN NUMBER,
                                    p_effective_date IN DATE,
                                    p_data_type      IN VARCHAR2)
  IS
  BEGIN
      generate_process_plan;

  END generate_process_planWF;

END lib_etl_plan_api;
/
