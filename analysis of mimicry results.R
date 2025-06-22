library(ggplot2)
library(tidyr)

population_data <- read.csv(file.choose())
head(population_data)

population_data_long <- pivot_longer(population_data, 
                          cols = c("Toxic", "Mimics", "Harmless", "Hawks"), 
                          names_to = "Type", 
                          values_to = "Count")

trait_data_long <- pivot_longer(population_data, 
                                     cols = c("AvgToxicity", "AvgMimicry"), 
                                     names_to = "Type", 
                                     values_to = "Value")

relative_data_long <- pivot_longer(population_data, 
                                   cols = c("RelativeToxic", "RelativeMimics", "RelativeHarmless"), 
                                   names_to = "Type", 
                                   values_to = "Count")

hawk_data_long <- pivot_longer(population_data, 
                               cols = c("LearnedAvoidance", "LearningSens"), 
                               names_to = "Type", 
                               values_to = "Value")

# population graph

ggplot(population_data_long, aes(x = Ticks, y = Count, color = Type)) +
  geom_line(size = 1) +
  theme_minimal() +
  labs(title = "Population Over Time",
       x = "Ticks",
       y = "Count") +
  scale_color_brewer(palette = "Dark2")

# relative bug population graph

ggplot(relative_data_long, aes(x = Ticks, y = Count, color = Type)) +
  geom_line(size = 1) +
  theme_minimal() +
  ylim(0, 100) +
  labs(title = "Population Over Time",
       x = "Ticks",
       y = "% Of Population") +
  scale_color_brewer(palette = "Dark2")

# toxicity graph

ggplot(trait_data_long, aes(x = Ticks, y = Value, color = Type)) + 
  geom_line(size = 1) +
  theme_minimal() +
  labs(title = "Mimicry and Toxicity Over Time",
      x = "Ticks",
      y = "Value") + 
  scale_color_brewer(palette = "Dark2")

# avoidance graph

ggplot(hawk_data_long, aes(x = Ticks, y = Value, color = Type)) +
  geom_line(size = 1) +
  theme_minimal() +
  labs(title = "Hawk Avoidance Over Time",
       x = "Ticks",
       y = "Mean Learned Avoidance") +
  scale_color_brewer(palette = "Dark2")


