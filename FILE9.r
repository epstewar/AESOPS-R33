#load libraries
library(tidyverse)
library(dplyr)
library(sqldf)
library(ggplot2)
library(haven)
library(readxl)
library(ggthemes)

#import figure 3 dta data 
mydat <- read_dta("/directory/figureS4_predictions.dta")

#convert assignment to factor 
mydat$randomization <- as.factor(mydat$assignment)

#add group colors for figure 
group.colors <- c("#999999", "darkorange")

#graph
ggplot(data = mydat, aes(x = wk, y = xb, shape = randomization, group = randomization, color = randomization)) +
  geom_line() +
  geom_segment(x = 0, y = 1, xend = 0, yend = 4, color = "#999999") +
  annotate('rect', xmin=0, xmax=79, ymin = 1, ymax = 4, fill = "lightblue", alpha = 0.5) +
  geom_point(size = 3) +
  scale_y_continuous(breaks = c(1,1.5,2,2.5,3,3.5,4), limits = c(1,4.5), expand = c(0,0), labels = c('1', '1.5', '2', '2.5', '3', '3.5', '4')) +
  scale_x_continuous(breaks = (seq(-30,110, by=10)), limits = c(-30, 110), expand = c(0,0)) +
  theme(axis.text.x = element_text(size = 2)) +
  geom_errorbar(aes(ymin=xb-error, ymax=xb+error)) +
  ylab("Adjusted Log MME") +
  xlab("Weeks Relative to Intervention Start") +
  theme_stata() +
  scale_color_manual(labels = c("Control", "Intervention"), values = group.colors) +
  scale_shape_manual(labels = c("Control", "Intervention"), values = c("0" = 16, "1" = 17)) +
  guides(color = guide_legend(title = NULL, position = "inside", override.aes = list(linetype = c(NA, NA))),
  shape = guide_legend(title = NULL, position = "inside")) +
  theme(legend.position = c(0.92, 0.82), 
        axis.title.x = element_text(vjust = -0.5), 
        axis.title.y = element_text(vjust = 2),
        plot.background = element_rect(fill = "white", color = NA),
        axis.text.x = element_text(size = 2)) +
  geom_segment(aes(x = 0, y = 4.2, xend = 79, yend = 4.2), color = "black") +
  geom_segment(aes(x = 0, y = 4.1, xend = 0, yend = 4.3), color = "black") +
  geom_segment(aes(x = 79, y = 4.1, xend = 79, yend = 4.3), color = "black") +
  annotate("text", x = 40, y = 4.3, label = "Intervention period") +
  theme(axis.line.y = element_blank(), axis.text.y = element_text(angle = 0)) +
  geom_segment(aes(x = -30, xend = -30, y = 1, yend = 4), color = "black")

#save figure S4
ggsave("/directory/figureS4.jpeg", width = 9, height = 4.95, units = "in", dpi = 300)
       
