---A general query to get a broad sense of the database.
SELECT *
FROM CustomerServiceChats

---Checking the amount of chats closed by Customers, System and Representatives.
SELECT Chat_Closed_By, COUNT(*) AS TotalChats
FROM CustomerServiceChats
GROUP BY Chat_Closed_By
ORDER BY TotalChats DESC;

---Analyzing how many ratings were received for each rating rank (0-10)
SELECT Customer_Rating, COUNT(*) AS RatingCount
FROM CustomerServiceChats
GROUP BY Customer_Rating
ORDER BY Customer_Rating DESC;

--- Average Response Time In Seconds Per Agent, Average Rating Per Agent, Total Chats per Agent.
SELECT Agent, AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTimeInSeconds, 
	AVG(Customer_Rating) AS AverageRating,
    COUNT(*) AS TotalChats
FROM CustomerServiceChats
GROUP BY Agent
ORDER BY AverageRating DESC, TotalChats DESC;

--- Agents Stats, Performance Feedback
WITH AgentStats AS (
    SELECT Agent, 
           AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTimeInSeconds,
           AVG(Customer_Rating) AS AverageRating, 
           COUNT(*) AS TotalChats,
           COUNT(CASE WHEN Chat_Closed_By IS NOT NULL THEN 1 END) AS ClosedChats,
           COUNT(CASE WHEN Transferred_Chat = 1 THEN 1 END) AS TransferredChats
    FROM CustomerServiceChats
    GROUP BY Agent
)

SELECT Agent, 
       AvgResponseTimeInSeconds, 
       AverageRating, 
       TotalChats, 
       ClosedChats, 
       TransferredChats,
       CASE 
           WHEN AverageRating < 4 THEN 'Needs Improvement'
           WHEN AverageRating >= 4 AND AverageRating < 7 THEN 'Good'
           ELSE 'Excellent'
       END AS PerformanceFeedback
FROM AgentStats
ORDER BY AverageRating DESC, AvgResponseTimeInSeconds ASC;

/* This next query calculates the percentile rank of each agent's average response time. It uses a window function to assign percentiles.
That is, essentially determining how an individual agent's performance compares to that of all other agents in the dataset*/

WITH AgentResponseTimes AS (
    SELECT Agent, AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTime
    FROM CustomerServiceChats
    GROUP BY Agent
)
SELECT Agent, AvgResponseTime,
    CONCAT(PERCENT_RANK() OVER (ORDER BY AvgResponseTime) * 100, '%') AS ResponseTimePercentile
FROM AgentResponseTimes;

--- This SQL query analyzes customer service performance by calculating the average response time and total number of chats handled for each hour on June 8, 2018, to identify patterns in response times relative to chat volume.
SELECT DATEPART(HOUR, Transaction_Start_Date) AS ResponseHour,
    AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTimeInSeconds,
    COUNT(*) AS ChatCount
FROM CustomerServiceChats
WHERE CAST(Transaction_Start_Date AS DATE) = '2018-06-08'
GROUP BY DATEPART(HOUR, Transaction_Start_Date)
ORDER BY ResponseHour;
--- 16:00PM is a peak hour with 2402 chats, and an average response time of 33, minimum action hour is 03:00AM with 101 chats, average response time of 29 seconds.

--- Checking Average Chats Per Agent for the Query afterwards to get an assesment about the medium engagement level.

SELECT AVG(TotalChats) AS AvgChatsPerAgent
FROM (
    SELECT Agent, COUNT(*) AS TotalChats
    FROM CustomerServiceChats
    GROUP BY Agent
) AS ChatCounts;

--- Checking engagement levels for each agent in the company.
WITH CustomerEngagement AS (
    SELECT Agent, AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTimeInSeconds, 
	AVG(Customer_Rating) AS AverageRating, COUNT(*) AS TotalChats
    FROM CustomerServiceChats
    GROUP BY Agent
)

SELECT Agent, CASE WHEN TotalChats < 30 THEN 'Low Engagement' WHEN TotalChats BETWEEN 30 AND 60 THEN 'Medium Engagement' ELSE 'High Engagement' END AS EngagementLevel,
    AverageRating,
    TotalChats
FROM CustomerEngagement
WHERE AverageRating IS NOT NULL
ORDER BY TotalChats DESC;


/*
The following query is designed to identify underutilized agents based on their engagement level and average customer rating.
By classifying agents into Low Engagement (handling fewer than 30 chats) and Medium Engagement (handling between 30 and 60 chats), 
it focuses on those who receive a perfect average rating of 10 from customers. These agents, despite their high performance, 
may not be handling as many chats as they could. The query helps management spot high-performing agents who are currently 
underutilized and recommend them for a higher workload, supporting workload balancing to improve customer service efficiency.
*/

WITH CustomerEngagement AS (
    SELECT Agent, AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTimeInSeconds, 
           AVG(Customer_Rating) AS AverageRating, 
           COUNT(*) AS TotalChats
    FROM CustomerServiceChats
    GROUP BY Agent
)

SELECT Agent, 
       CASE WHEN TotalChats < 30 THEN 'Low Engagement' WHEN TotalChats BETWEEN 30 AND 60 THEN 'Medium Engagement' ELSE 'High Engagement' 
       END AS EngagementLevel,
       AverageRating,
       TotalChats
FROM CustomerEngagement
WHERE AverageRating = 10  -- Filter for agents with average rating of 10
AND (TotalChats < 30 OR TotalChats BETWEEN 30 AND 60)  -- Filter for Low and Medium Engagement
ORDER BY TotalChats DESC;

/*
This query provides a comprehensive analysis of customer service chat activity and agent performance throughout the day.
It breaks down chat volumes, average response times, customer ratings, and the number of active agents by each hour.
Additionally, it calculates a rolling sum of total chats to reveal cumulative workload trends as the day progresses.
A new column, ChatsPerAgent, shows the ratio of chats to active agents, offering insights into how evenly the workload is distributed among agents.

By analyzing peak hours, you can assess whether response times and customer satisfaction are affected when chat volumes are high,
and whether the number of agents was sufficient to handle the demand.
The rolling sum and chat-per-agent ratio together help identify both cumulative demand and per-agent workload.
This data can assist in developing strategies for workload balancing,
ensuring that the right number of agents is allocated during busier times to maintain quick response times and high customer satisfaction.
*/

WITH HourlyChatAnalysis AS (
    SELECT 
        DATEPART(HOUR, Transaction_Start_Date) AS HourOfDay,
        COUNT(*) AS TotalChats,
        AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTimeInSeconds,
        AVG(Customer_Rating) AS AverageRating
    FROM CustomerServiceChats
    WHERE CAST(Transaction_Start_Date AS DATE) = '2018-06-08'
    GROUP BY DATEPART(HOUR, Transaction_Start_Date)
),
ActiveAgentsPerHour AS (
    SELECT 
        DATEPART(HOUR, Transaction_Start_Date) AS HourOfDay,
        COUNT(DISTINCT Agent) AS ActiveAgents
    FROM CustomerServiceChats
    WHERE Agent IS NOT NULL
    GROUP BY DATEPART(HOUR, Transaction_Start_Date)
)

SELECT 
    hca.HourOfDay,
    hca.TotalChats,
    hca.AvgResponseTimeInSeconds,
    hca.AverageRating,
    aap.ActiveAgents,
    SUM(hca.TotalChats) OVER (ORDER BY hca.HourOfDay ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Rolling_Chats_Sum,
    ROUND(CAST(hca.TotalChats AS FLOAT) / NULLIF(aap.ActiveAgents, 0),2) AS ChatsPerAgent -- Calculate total chats per active agent
FROM HourlyChatAnalysis hca
JOIN ActiveAgentsPerHour aap
    ON hca.HourOfDay = aap.HourOfDay
ORDER BY hca.HourOfDay ASC;

/* 
This next query examines the correlation between the number of chats handled by each agent and their average customer ratings. 
It calculates the total chats and average ratings for each agent, categorizing them into low, medium, and high volume groups. 
The results help identify trends in customer satisfaction relative to chat volume, providing insights into whether higher workloads impact ratings. 
*/

WITH ChatVolume AS (
    SELECT Agent, COUNT(*) AS TotalChats, AVG(Customer_Rating) AS AvgRating
    FROM CustomerServiceChats
    GROUP BY Agent
)

SELECT CASE WHEN TotalChats < 30 THEN 'Low Volume'WHEN TotalChats BETWEEN 30 AND 60 THEN 'Medium Volume' ELSE 'High Volume'
    END AS ChatVolumeCategory,
    AVG(AvgRating) AS AvgRating,
    COUNT(*) AS AgentCount
FROM ChatVolume
GROUP BY CASE WHEN TotalChats < 30 THEN 'Low Volume'WHEN TotalChats BETWEEN 30 AND 60 THEN 'Medium Volume' ELSE 'High Volume' END
ORDER BY AgentCount ASC;

/* 
The next analysis evaluates agent performance based on the complexity of customer chats, categorizing them into 'Simple', 'Medium', and 'Complex' based on the length of the chat text.
Notably, all agents exhibited an impressive average rating of 10, highlighting a consistent level of customer satisfaction across varying chat complexities.
Such uniformity suggests that agents are effectively managing customer interactions, regardless of the chat's difficulty.
Additionally, average response times, particularly in complex chats, provide insights into potential workload disparities among agents.
Identifying agents who excel in handling more intricate queries may reveal opportunities for mentorship or resource allocation to further enhance their skills.
By leveraging this data, we can develop targeted training programs that focus on improving efficiency and service quality.
Ultimately, this analysis not only informs staffing strategies but also lays the groundwork for ongoing performance improvement initiatives, ensuring that all agents are equipped to deliver high-quality customer service, regardless of the chat complexity they encounter.
*/

SELECT Agent, CASE 
        WHEN LEN(Text) < 500 THEN 'Simple'
        WHEN LEN(Text) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Complex'
		END AS ChatComplexity,
    AVG(Customer_Rating) AS AvgRating, 
    AVG(DATEDIFF(SECOND, 0, Response_Time_of_Agent)) AS AvgResponseTime
FROM CustomerServiceChats
GROUP BY Agent, CASE 
        WHEN LEN(Text) < 500 THEN 'Simple'
        WHEN LEN(Text) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Complex'
    END
	ORDER BY AvgRating DESC;
