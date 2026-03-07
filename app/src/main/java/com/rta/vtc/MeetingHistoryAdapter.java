package com.rta.vtc;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class MeetingHistoryAdapter extends RecyclerView.Adapter<MeetingHistoryAdapter.ViewHolder> {

    private List<PrefsManager.MeetingItem> items;
    private final OnItemClickListener listener;

    public interface OnItemClickListener {
        void onItemClick(String roomName);
    }

    public MeetingHistoryAdapter(List<PrefsManager.MeetingItem> items, OnItemClickListener listener) {
        this.items = items;
        this.listener = listener;
    }

    public void updateItems(List<PrefsManager.MeetingItem> newItems) {
        this.items = newItems;
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_meeting, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        PrefsManager.MeetingItem item = items.get(position);
        holder.txtRoomName.setText(item.roomName);

        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault());
        holder.txtTimestamp.setText(sdf.format(new Date(item.timestamp)));

        holder.itemView.setOnClickListener(v -> listener.onItemClick(item.roomName));
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView txtRoomName;
        TextView txtTimestamp;

        ViewHolder(View itemView) {
            super(itemView);
            txtRoomName = itemView.findViewById(R.id.txtRoomName);
            txtTimestamp = itemView.findViewById(R.id.txtTimestamp);
        }
    }
}
